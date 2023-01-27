# This Dockerfile uses two separate stages; a build stage and a run phase.
# - In the build phase, the Elixir tooling is used to assemble a release.
# - After the build phase, Elixir and its dependencies are no longer required.
#   the run phase uses a stripped down container which executes the release.

ARG ELIXIR_VERSION=1.14.3
ARG OTP_VERSION=25.2.1
ARG DEBIAN_VERSION=buster-20230109-slim
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

# ----------- #
# Build Phase #
# ----------- #

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# copy application files
COPY assets assets
COPY priv priv
COPY lib lib

# compile assets
RUN mix assets.deploy

# Compile the application code
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

# Copy release scripts
COPY rel rel

# Compile the release
RUN mix release

# --------- #
# Run Phase #
# --------- #

FROM ${RUNNER_IMAGE}

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Drop permissions
WORKDIR "/app"
RUN chown nobody /app
USER nobody

# Copy the release to the container
ENV MIX_ENV="prod"
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/training_schedule ./

# Set up the database path
ENV TS_DB_PATH="/data/training_schedule.db"
VOLUME /data

CMD ["/app/bin/entrypoint"]
