# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

from jupyter_core.paths import jupyter_data_dir
import subprocess
import os
import errno
import stat

c = get_config()
startup = [
   'from metakernel import register_ipython_magics',
   'register_ipython_magics()',
]
c.InteractiveShellApp.exec_lines = startup
c.NotebookApp.ip = '*'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False

# https://github.com/jupyter/notebook/issues/3130
c.FileContentsManager.delete_to_trash = False

#c.NBNoVNC.vnc_command = "xinit -- /usr/bin/Xtightvnc :{display} -geometry {geometry} -depth {depth} -auth /home/jovyan/.Xauthority"
c.NBNoVNC.vnc_command = "xinit -- /usr/bin/Xorg :{display} +extension GLX +extension RANDR +extension RENDER -listen tcp -config /etc/X11/xorg.conf -auth /home/jovyan/.Xauthority"
c.NBNoVNC.helper_command = "x11vnc -xkb -rfbport {vnc_port}"
c.NBNoVNC.websockify_command = "/opt/conda/envs/py2/bin/websockify --web {novnc_directory} --heartbeat {heartbeat} {port} localhost:{vnc_port}"

c.NBNoVNC.geometry = "1280x768"

# Set the iopub data rate limit to 60MB/s
c.NotebookApp.iopub_data_rate_limit=60000000000
c.NotebookApp.rate_limit_window=1.0
c.NotebookApp.limit_output=60000000000

# Generate a self-signed certificate
if 'GEN_CERT' in os.environ:
    dir_name = jupyter_data_dir()
    pem_file = os.path.join(dir_name, 'notebook.pem')
    try:
        os.makedirs(dir_name)
    except OSError as exc:  # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(dir_name):
            pass
        else:
            raise
    # Generate a certificate if one doesn't exist on disk
    subprocess.check_call(['openssl', 'req', '-new',
                           '-newkey', 'rsa:2048',
                           '-days', '365',
                           '-nodes', '-x509',
                           '-subj', '/C=XX/ST=XX/L=XX/O=generated/CN=generated',
                           '-keyout', pem_file,
                           '-out', pem_file])
    # Restrict access to the file
    os.chmod(pem_file, stat.S_IRUSR | stat.S_IWUSR)
    c.NotebookApp.certfile = pem_file


