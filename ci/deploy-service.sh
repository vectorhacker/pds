echo "Starting deployment for service $service version $VERSION"

# Create or update service
nomad run $service/$nomad_file