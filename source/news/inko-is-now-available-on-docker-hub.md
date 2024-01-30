---
{
  "title": "Inko is now available on Docker Hub",
  "date": "2020-10-25 00:46:53 UTC"
}
---

You can now install Inko using [Docker](https://www.docker.com/) or
[Podman](https://podman.io/), as we now publish official Docker images to Docker
Hub.

Our Docker images are published in the [inkolang/inko Docker Hub
repository](https://hub.docker.com/r/inkolang/inko), and are based on Alpine
Linux. You can install these images as follows:

```bash
docker pull inkolang/inko:0.8.1 # When using Docker
podman pull inkolang/inko:0.8.1 # When using Podman
```

You can then run Inko as follows:

```bash
docker run inkolang/inko:0.8.1 inko --version # When using Docker
podman run inkolang/inko:0.8.1 inko --version # When using Podman
```

For now we only publish Docker images for tags, so there's no "latest" tag.

For more information, refer to the [Docker installation
manual](https://docs.inko-lang.org/manual/master/getting-started/installation/#docker).
