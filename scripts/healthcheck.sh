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

http_code() {
  local url="$1"
  curl --silent --output /dev/null --write-out '%{http_code}' --max-time 8 "$url" 2>/dev/null || true
}

container_running() {
  local name="$1"
  [[ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)" == "true" ]]
}

echo "QuietGate health check"
echo

if [[ ! -f "docker-compose.yml" ]]; then
  fail "Run this script from the repository root."
else
  pass "Repository root looks correct."
fi

for cmd in docker tailscale curl; do
  if have_command "$cmd"; then
    pass "Required command is available: ${cmd}"
  else
    fail "Required command is missing: ${cmd}"
  fi
done

if have_command docker && docker compose version >/dev/null 2>&1; then
  pass "Docker Compose is available."
else
  fail "Docker Compose is not available through 'docker compose'."
fi

if [[ -f ".env" ]]; then
  pass ".env exists."
else
  fail ".env is missing. Copy .env.example to .env and fill it in."
fi

TAILSCALE_IP=""
BASE_DOMAIN=""
HOMEPAGE_ALLOWED_HOSTS=""
HOMEPAGE_CONFIG_DIR=""

if [[ -f ".env" ]]; then
  TAILSCALE_IP="$(read_env_var TAILSCALE_IP)"
  BASE_DOMAIN="$(read_env_var BASE_DOMAIN)"
  HOMEPAGE_ALLOWED_HOSTS="$(read_env_var HOMEPAGE_ALLOWED_HOSTS)"
  HOMEPAGE_CONFIG_DIR="$(read_env_var HOMEPAGE_CONFIG_DIR)"
fi

for var_name in TAILSCALE_IP BASE_DOMAIN HOMEPAGE_ALLOWED_HOSTS HOMEPAGE_CONFIG_DIR; do
  if [[ -n "${!var_name:-}" ]]; then
    pass "Required .env value is set: ${var_name}"
  else
    fail "Required .env value is missing: ${var_name}"
  fi
done

current_tailscale_ip=""
if have_command tailscale; then
  current_tailscale_ip="$(tailscale ip -4 2>/dev/null | head -n 1 || true)"
fi

if [[ -n "$current_tailscale_ip" ]]; then
  pass "Tailscale has an IPv4 address."
else
  fail "Tailscale does not appear to have an IPv4 address."
fi

if [[ -n "$TAILSCALE_IP" && -n "$current_tailscale_ip" ]]; then
  if [[ "$TAILSCALE_IP" == "$current_tailscale_ip" ]]; then
    pass "TAILSCALE_IP matches the current Tailscale IPv4 address."
  else
    fail "TAILSCALE_IP does not match the current Tailscale IPv4 address."
  fi
fi

if [[ -f "config/homepage/services.yaml" ]]; then
  pass "Homepage services config exists."
else
  fail "Homepage services config is missing. Create it from config/homepage/services.yaml.template."
fi

if have_command docker; then
  if docker compose config >/dev/null 2>&1; then
    pass "Docker Compose configuration is valid."
  else
    fail "Docker Compose configuration did not validate."
  fi
fi

for container in phgk-traefik phgk-homepage phgk-uptime-kuma phgk-whoami; do
  if have_command docker && container_running "$container"; then
    pass "Container is running: ${container}"
  else
    fail "Expected container is not running: ${container}"
  fi
done

if [[ -n "$BASE_DOMAIN" ]] && have_command curl; then
  homepage_status="$(http_code "http://homepage.${BASE_DOMAIN}")"
  if [[ "$homepage_status" == "200" ]]; then
    pass "Homepage returns HTTP 200."
  else
    fail "Homepage did not return HTTP 200."
  fi

  uptime_status="$(http_code "http://uptime.${BASE_DOMAIN}")"
  if [[ "$uptime_status" == "200" || "$uptime_status" == "302" || "$uptime_status" == "307" ]]; then
    pass "Uptime Kuma responds."
  else
    fail "Uptime Kuma did not return an expected response."
  fi

  whoami_status="$(http_code "http://whoami.${BASE_DOMAIN}")"
  if [[ "$whoami_status" == "200" ]]; then
    pass "Whoami responds."
  else
    fail "Whoami did not respond with HTTP 200."
  fi

  traefik_status="$(http_code "http://traefik.${BASE_DOMAIN}/dashboard/")"
  if [[ "$traefik_status" == "404" ]]; then
    pass "Traefik dashboard returns 404 as expected."
  elif [[ "$traefik_status" == "000" ]]; then
    warn "Could not reach the Traefik dashboard check URL."
  else
    fail "Traefik dashboard did not return 404."
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
    warn "Port 80 appears to be listening on 0.0.0.0. Review the Traefik port binding."
  else
    pass "Port 80 is not listening on 0.0.0.0."
  fi
else
  warn "The 'ss' command is missing, so the port binding check was skipped."
fi

echo
echo "Summary: ${pass_count} passed, ${warn_count} warnings, ${fail_count} failures."

if [[ "$fail_count" -gt 0 ]]; then
  echo "Result: health check failed. Fix the FAIL items before adding more apps."
  exit 1
fi

echo "Result: health check passed. Review any WARN items before making changes."
