#!/usr/bin/env bash

set -u

fail_count=0
warn_count=0
pass_count=0

pass() {
  printf 'PASS: %s\n' "$1"
  pass_count=$((pass_count + 1))
}

warn() {
  printf 'WARN: %s\n' "$1"
  warn_count=$((warn_count + 1))
}

fail() {
  printf 'FAIL: %s\n' "$1"
  fail_count=$((fail_count + 1))
}

have_command() {
  command -v "$1" >/dev/null 2>&1
}

read_env_var() {
  local key="$1"
  local line value

  line="$(grep -E "^[[:space:]]*${key}=" .env 2>/dev/null | tail -n 1 || true)"
  value="${line#*=}"

  # Trim surrounding whitespace and one matching layer of quotes.
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  if [[ "${value}" == \"*\" && "${value}" == *\" ]]; then
    value="${value:1:${#value}-2}"
  elif [[ "${value}" == \'*\' && "${value}" == *\' ]]; then
    value="${value:1:${#value}-2}"
  fi

  printf '%s' "$value"
}

extract_service_block() {
  local service_name="$1"
  awk -v name="$service_name" '
    $0 ~ "^  " name ":" { active = 1; print; next }
    active && $0 ~ "^  [A-Za-z0-9_-]+:" { active = 0 }
    active { print }
  '
}

count_public_web_binds() {
  awk '
    function clean(value) {
      gsub(/"/, "", value)
      return value
    }

    function check_item() {
      if ((published == "80" || published == "443") && (host_ip == "" || host_ip == "0.0.0.0")) {
        count++
      }
    }

    /^      - / {
      check_item()
      host_ip = ""
      published = ""
      next
    }

    /host_ip:/ {
      host_ip = clean($2)
      next
    }

    /published:/ {
      published = clean($2)
      next
    }

    END {
      check_item()
      print count + 0
    }
  '
}

echo "Private Homelab Gateway Kit exposure check"
echo
echo "Note: this checks local host and Docker bindings only."
echo "It cannot prove whether your router or firewall has public port forwarding enabled."
echo

if [[ ! -f "docker-compose.yml" ]]; then
  fail "Run this script from the repository root."
else
  pass "Repository root looks correct."
fi

for cmd in docker ss; do
  if have_command "$cmd"; then
    pass "Required command is available: ${cmd}"
  else
    fail "Required command is missing: ${cmd}"
  fi
done

if [[ -f ".env" ]]; then
  pass ".env exists."
else
  fail ".env is missing. Copy .env.example to .env and fill it in."
fi

TAILSCALE_IP=""
if [[ -f ".env" ]]; then
  TAILSCALE_IP="$(read_env_var TAILSCALE_IP)"
fi

if [[ -n "$TAILSCALE_IP" ]]; then
  pass "TAILSCALE_IP is set in .env."
else
  fail "TAILSCALE_IP is missing from .env."
fi

compose_config=""
traefik_block=""

if have_command docker; then
  if compose_config="$(docker compose config 2>/dev/null)"; then
    pass "Docker Compose configuration is valid."
    traefik_block="$(printf '%s\n' "$compose_config" | extract_service_block traefik)"
  else
    fail "Docker Compose configuration did not validate."
  fi
fi

if [[ -n "$traefik_block" ]]; then
  if grep -Fq "host_ip: ${TAILSCALE_IP}" <<<"$traefik_block" &&
    grep -Eq 'published: "?80"?' <<<"$traefik_block" &&
    grep -Eq 'target: 80' <<<"$traefik_block"; then
    pass "Rendered Compose binds Traefik port 80 to the configured Tailscale IP."
  else
    fail "Rendered Compose does not clearly bind Traefik port 80 to the configured Tailscale IP."
  fi

  traefik_public_binds="$(printf '%s\n' "$traefik_block" | count_public_web_binds)"
  if [[ "$traefik_public_binds" -gt 0 ]]; then
    fail "Rendered Traefik config includes an all-interface bind for port 80 or 443."
  else
    pass "Rendered Traefik config does not show an all-interface bind for port 80 or 443."
  fi
else
  fail "Could not find the Traefik service in rendered Compose config."
fi

if [[ -n "$compose_config" ]]; then
  public_binds="$(printf '%s\n' "$compose_config" | count_public_web_binds)"
  if [[ "$public_binds" -gt 0 ]] || grep -Eq '0\.0\.0\.0:(80|443)' <<<"$compose_config"; then
    fail "Rendered Compose includes an obvious all-interface bind for port 80 or 443."
  else
    pass "Rendered Compose does not show obvious all-interface binds for ports 80 or 443."
  fi

  if grep -q 'traefik.http.routers.traefik' <<<"$compose_config"; then
    fail "Rendered Compose includes a Traefik dashboard route."
  else
    pass "Rendered Compose does not include a Traefik dashboard route."
  fi
fi

if have_command ss; then
  listen_lines="$(ss -H -ltn 2>/dev/null || true)"

  if [[ -n "$TAILSCALE_IP" ]] && grep -Fq "${TAILSCALE_IP}:80" <<<"$listen_lines"; then
    pass "Port 80 is listening on the configured Tailscale IP."
  else
    fail "Port 80 does not appear to be listening on the configured Tailscale IP."
  fi

  if grep -Eq '(^|[[:space:]])0\.0\.0\.0:80[[:space:]]' <<<"$listen_lines"; then
    fail "Port 80 is listening on 0.0.0.0. Review the Traefik port binding."
  else
    pass "Port 80 is not listening on 0.0.0.0."
  fi

  if grep -Eq '(^|[[:space:]])0\.0\.0\.0:443[[:space:]]' <<<"$listen_lines"; then
    fail "Port 443 is listening on 0.0.0.0. Review other services before continuing."
  else
    pass "Port 443 is not listening on 0.0.0.0."
  fi
fi

echo
echo "Summary: ${pass_count} passed, ${warn_count} warnings, ${fail_count} failures."

if [[ "$fail_count" -gt 0 ]]; then
  echo "Result: exposure check failed. Fix the FAIL items before assuming the setup is private."
  exit 1
fi

echo "Result: exposure check passed for local host and Docker bindings."
echo "Reminder: this does not verify router or firewall port forwarding."
