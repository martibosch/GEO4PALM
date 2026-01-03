# --------------------------------------------------------------
# 1. base image - miniconda
# --------------------------------------------------------------
FROM continuumio/miniconda3:latest AS base

# --------------------------------------------------------------
# 1. install mamba (much faster than conda)
# --------------------------------------------------------------
RUN conda install -n base -c conda-forge mamba && \
    conda clean -afy

# --------------------------------------------------------------
# 3. create the GEO4PALM environment from the YAML environment
# --------------------------------------------------------------
#   - the original file is named geo4palm_env.yml in the repo.
#   - we copy it into the image, then create the env with mamba.
# --------------------------------------------------------------
COPY geo4palm_env.yml /tmp/geo4palm_env.yml

# create the environment called "geo4palm"
RUN mamba env create -f /tmp/geo4palm_env.yml && \
    # activate the env for later RUN steps
    echo "source activate geo4palm" > /etc/profile.d/conda.sh && \
    conda clean -afy

# --------------------------------------------------------------
# 4. install terracatalogueclient with the custom index
# --------------------------------------------------------------
#   - we need the exact pip executable that belongs to the env.
#   - using `conda run -n geo4palm` guarantees we invoke the right pip.
# --------------------------------------------------------------
RUN /opt/conda/envs/geo4palm/bin/pip install \
        terracatalogueclient \
        -i https://artifactory.vgt.vito.be/api/pypi/python-packages-public/simple \
    && conda clean -afy

# --------------------------------------------------------------
# 5. copy the repository source code into the image
# --------------------------------------------------------------
WORKDIR /app
COPY . /app

# --------------------------------------------------------------
# 6. get the default command – start the Panel UI
# --------------------------------------------------------------
#   - users can override the port or add extra flags at runtime.
#   - example:  docker run -p 8081:8081 <image> --port 8081 --show
# --------------------------------------------------------------
ENV PATH=/opt/conda/envs/geo4palm/bin:$PATH
EXPOSE 8081

# ENTRYPOINT runs *inside* the activated env.
# the `exec "$@"` form forwards signals correctly and lets you replace the whole
# process with the command you supply.
# CMD ["panel", "serve", "--port", "8081", "palm_domain_utility.py", "--show"]
ENTRYPOINT ["sh", "-c", "exec \"$@\"", "--"]
