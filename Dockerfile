############################
# Étape de compilation
############################
FROM hexpm/elixir:1.16.3-erlang-24.3.4.2-debian-bookworm-20251117-slim AS build

ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV} \
    LANG=C.UTF-8

WORKDIR /app

# Dépendances système nécessaires à la compilation d'un release Phoenix
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

RUN mix local.hex --force && \
    mix local.rebar --force

# Pré-chargement des dépendances Elixir
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only ${MIX_ENV} && \
    mix deps.compile

# Compilation de l'app + assets
COPY . .
RUN mix assets.deploy && \
    mix release

############################
# Étape d'exécution
############################
FROM debian:bookworm-20240812-slim AS app

ENV LANG=C.UTF-8 \
    MIX_ENV=prod \
    PHX_SERVER=true \
    SHELL=/bin/bash

WORKDIR /app

# Bibliothèques nécessaires au runtime Erlang/Elixir
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      libstdc++6 \
      openssl \
      ncurses-base \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build /app/_build/prod/rel/traceroute_monitor ./traceroute_monitor

EXPOSE 4000

ENTRYPOINT ["./traceroute_monitor/bin/traceroute_monitor"]
CMD ["start"]

