# kevin-hermes — Kevin primary instance image
# Process skills: baked from dist/hermes after publish (never raw src/).
#
# Build (from agent-tools repo root):
#   docker build -f hermes/docker/Dockerfile -t kevin-hermes:local .

# ── publish: hermes dist only ───────────────────────────────────────
FROM debian:bookworm-slim AS publish
RUN apt-get update \
  && apt-get install -y --no-install-recommends bash ca-certificates git \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN bash tools/publish-skills.sh --agents hermes \
  && test -d dist/hermes/skills \
  && test -n "$(ls -A dist/hermes/skills)" \
  && printf 'agent-tools-rev=%s\ninstalled-at=%s\npublish-agent=hermes\n' \
       "$(git rev-parse HEAD 2>/dev/null || echo unknown)" \
       "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
       > dist/hermes/skills/.agent-tools-revision

# ── runtime ─────────────────────────────────────────────────────────
FROM nousresearch/hermes-agent:latest

USER root
COPY --from=publish /src/dist/hermes/skills /opt/kevin/skills
COPY hermes/profile /opt/kevin/profile
COPY hermes/docker/entrypoint.sh /opt/kevin/entrypoint.sh
RUN chmod 755 /opt/kevin/entrypoint.sh \
  && chmod -R a+rX /opt/kevin/skills /opt/kevin/profile \
  && test -f /opt/kevin/skills/.agent-tools-revision

LABEL org.kevin.image="kevin-hermes" \
      org.kevin.skills_path="/opt/kevin/skills" \
      org.kevin.profile_path="/opt/kevin/profile"

# Keep upstream ENTRYPOINT (/init). CMD is our ensure-profile + gateway.
CMD ["/opt/kevin/entrypoint.sh"]
