# JupyterLab Server Configuration for FlumenData
c = get_config()  # noqa

# Disable authentication
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.disable_check_xsrf = True

# Allow remote access
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_remote_access = True

# Default to JupyterLab interface
c.ServerApp.default_url = '/lab'
