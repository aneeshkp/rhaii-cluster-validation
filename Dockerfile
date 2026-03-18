# Build stage
FROM registry.access.redhat.com/ubi9/go-toolset:1.25 AS builder

WORKDIR /opt/app-root/src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG VERSION=dev
RUN CGO_ENABLED=0 GOOS=linux go build -buildvcs=false -ldflags "-X main.version=${VERSION}" -o /opt/app-root/rhaii-validator ./cmd/agent/

# Runtime stage
FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL name="rhaii-validator" \
      vendor="Red Hat" \
      summary="RHAII Cluster Validation Agent" \
      description="Per-node hardware validation agent for GPU, RDMA, and network checks"

# Agent only needs util-linux (chroot) and pciutils (lspci)
# GPU/RDMA tools run on the host via chroot /host
RUN dnf install -y \
      util-linux \
      pciutils \
      && dnf clean all

COPY --from=builder /opt/app-root/rhaii-validator /usr/local/bin/rhaii-validator

# Agent checks: GPU/RDMA tools run on host via chroot /host
# Job tests: iperf3, ib_write_bw run directly in the container

USER 0

ENTRYPOINT ["rhaii-validator"]
