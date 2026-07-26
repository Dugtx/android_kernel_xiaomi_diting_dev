# Third-party components

The release ZIP is assembled from unmodified upstream downloads plus the
documented equal-length Android path substitutions applied by this project.
The large binaries are release inputs and are not committed to this repository.

| Component | Pinned version | Upstream | License |
| --- | --- | --- | --- |
| Docker Engine static bundle | 28.5.2 | `download.docker.com` | Apache-2.0 components |
| Docker Buildx | 0.35.0 | `github.com/docker/buildx` | Apache-2.0 |
| Docker Compose | 5.3.1 | `github.com/docker/compose` | Apache-2.0 |
| containerd | bundled with Engine 28.5.2 | `github.com/containerd/containerd` | Apache-2.0 |
| runc | bundled with Engine 28.5.2 | `github.com/opencontainers/runc` | Apache-2.0 |

The package includes the Apache-2.0 license text and a generated SHA-256
manifest. Component source and notices remain available from the linked
upstream projects. This project does not relicense those components.
