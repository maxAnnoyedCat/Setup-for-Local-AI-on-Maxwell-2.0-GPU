# Setup für Lokale KI auf Maxwell 2.0 GPU

Dieses Repository dokumentiert die produktionsbereite Konfiguration für den Betrieb lokaler Large Language Models (LLMs) auf der NVIDIA Maxwell 2.0 Architektur (Compute Capability 5.2). Das Setup realisiert eine isolierte Containerisierung via Podman und eine deklarative System-Orchestrierung unter NixOS.

## Stack-Übersicht
- **Host-OS:** NixOS 25.11 (Xantusia)
- **Container-Engine:** Podman (Rootless, OCI-konforme Runtime)
- **AI-Runtime:** Ollama (Latest)
- **Ziel-Hardware:** NVIDIA Maxwell 2.0 (Optimiert für Legacy-CUDA-Treiberzweige)

---

## Native Podman Container-Inspektion

Um die hardwareseitige Durchreichung und OCI-Konformität im Live-Betrieb zu validieren, wurde eine native Runtime-Inspektion durchgeführt. Der folgende Terminal-Auschnitt zeigt die vollständige infrastrukturelle Einbettung, die spezifischen Image-Layer sowie die für die GPU-Beschleunigung kritischen Umgebungsvariablen (`Env`):

```bash
$ sudo podman inspect ollama
[
     {
          "Id": "d68df3e0e063d59b82fbdbbc21dd9e6e7cb797e695cca2de2ab9bf6292a43bee",
          "Digest": "sha256:f75b63e35e2aba7accd9af41dbfb10f19a72670351d678c172e6dab64407750b",
          "RepoTags": [
               "docker.io/ollama/ollama:latest"
          ],
          "RepoDigests": [
               "docker.io/ollama/ollama@sha256:2038a264392af4d21f7f14e1568e8dd9aa0f2bd0f31d7d9a59a8cca1e9829663",
               "docker.io/ollama/ollama@sha256:f75b63e35e2aba7accd9af41dbfb10f19a72670351d678c172e6dab64407750b"
          ],
          "Parent": "",
          "Comment": "",
          "Created": "2026-04-24T02:23:27.02872534Z",
          "Config": {
               "ExposedPorts": {
                    "11434/tcp": {}
               },
               "Env": [
                    "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                    "LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64",
                    "NVIDIA_DRIVER_CAPABILITIES=compute,utility",
                    "NVIDIA_VISIBLE_DEVICES=all",
                    "OLLAMA_HOST=0.0.0.0:11434"
               ],
               "Entrypoint": [
                    "/bin/ollama"
               ],
               "Cmd": [
                    "serve"
               ],
               "Labels": {
                    "org.opencontainers.image.version": "24.04"
               },
               "ArgsEscaped": true
          },
          "Version": "",
          "Author": "",
          "Architecture": "amd64",
          "Os": "linux",
          "Size": 6301949086,
          "VirtualSize": 6301949086,
          "GraphDriver": {
               "Name": "overlay",
               "Data": {
                    "LowerDir": "/var/lib/containers/storage/overlay/56d8ab9198c1d88ab16e858b8d062adc43a9f0e3cab1af46e1e751cac123558f/diff:/var/lib/containers/storage/overlay/efbeafc8d46bd290886f4c077be7cd0086b3b0cc9c75bacae57b730a9c7e37de/diff:/var/lib/containers/storage/overlay/538812a4b9bd45adaac2b5e5b967daa6999aa44eb110aa32ae7c69702b906475/diff",
                    "UpperDir": "/var/lib/containers/storage/overlay/9b11b662f85fdbbb6badd3bfdd17e646f997c132d54122b2e854c79a1450b7ec/diff",
                    "WorkDir": "/var/lib/containers/storage/overlay/9b11b662f85fdbbb6badd3bfdd17e646f997c132d54122b2e854c79a1450b7ec/work"
               }
          },
          "RootFS": {
               "Type": "layers",
               "Layers": [
                    "sha256:538812a4b9bd45adaac2b5e5b967daa6999aa44eb110aa32ae7c69702b906475",
                    "sha256:22f13d60ab54a17161ecc440e8e9214fae07240669ae11f8224ec6b03fa7e1aa",
                    "sha256:175855cb7dcc7e2a4c1e084c4c65f710e18ed480a4024441e159ee2ff2b9ce3c",
                    "sha256:027025eeffd409bf3fc2991c3679d816b695845b19c449dd04fa1a5b036fea8b"
               ]
          },
          "Labels": {
               "org.opencontainers.image.version": "24.04"
          },
          "Annotations": {},
          "ManifestType": "application/vnd.oci.image.manifest.v1+json",
          "User": "",
          "History": [
               {
                    "created": "2026-04-10T06:49:15.45210454Z",
                    "created_by": "/bin/sh -c #(nop)  ARG RELEASE",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-10T06:49:15.493474875Z",
                    "created_by": "/bin/sh -c #(nop)  ARG LAUNCHPAD_BUILD_ARCH",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-10T06:49:15.521658623Z",
                    "created_by": "/bin/sh -c #(nop)  LABEL org.opencontainers.image.version=24.04",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-10T06:49:17.706887224Z",
                    "created_by": "/bin/sh -c #(nop) ADD file:8ce1caf246e7c778bca84c516d02fd4e83766bb2c530a0fffa8a351b560a2728 in / "
               },
               {
                    "created": "2026-04-10T06:49:18.133477895Z",
                    "created_by": "/bin/sh -c #(nop)  CMD [\"/bin/bash\"]",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-17T03:56:02.704288816Z",
                    "created_by": "RUN /bin/sh -c apt-get update     && apt-get install -y ca-certificates libvulkan1 libopenblas0     && apt-get clean     && rm -rf /var/lib/apt/lists/* # buildkit",
                    "comment": "buildkit.dockerfile.v0"
               },
               {
                    "created": "2026-04-24T02:23:23.79316652Z",
                    "created_by": "COPY /bin /usr/bin # buildkit",
                    "comment": "buildkit.dockerfile.v0"
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "COPY /lib/ollama /usr/lib/ollama # buildkit",
                    "comment": "buildkit.dockerfile.v0"
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENV LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENV NVIDIA_VISIBLE_DEVICES=all",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENV OLLAMA_HOST=0.0.0.0:11434",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "EXPOSE [11434/tcp]",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "ENTRYPOINT [\"/bin/ollama\"]",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               },
               {
                    "created": "2026-04-24T02:23:27.02872534Z",
                    "created_by": "CMD [\"serve\"]",
                    "comment": "buildkit.dockerfile.v0",
                    "empty_layer": true
               }
          ],
          "NamesHistory": [
               "docker.io/ollama/ollama:latest"
          ]
     }
]
