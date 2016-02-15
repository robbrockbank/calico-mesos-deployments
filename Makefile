default: help
docker_image: dockerized-mesos/.dockerized_mesos.created ## Create the calico/mesos-calico image
docker_image.tar: dist/docker/mesos-calico.tar ## Create the calico/mesos-calico image, and tar it.

# TODO: maybe change this so docker runs and handles the caching itself,
# instead of relying on the .created file.
dockerized-mesos/.dockerized_mesos.created:
	docker build -t calico/mesos-calico:0.27.0-1 .
	touch dockerized-mesos/.mesos_calico_image.created

# Tar up the calico/mesos-calico docker image
dist/docker/mesos-calico.tar: docker_image
	mkdir -p dist/docker
	docker save -o dist/docker/mesos-calico.tar calico/mesos-calico:0.27.0-1

## Create the calico-mesos RPM
rpm:
	mkdir -p -m 777 dist/rpm/
	docker build -t calico/mesos-rpm-builder ./packages
	docker run \
	-v `pwd`/dist/rpm/:/root/rpmbuild/RPMS/ \
	calico/mesos-rpm-builder

## Clean everything (including stray volumes)
clean:
	find . -name '*.created' -exec rm -f {} +
	-rm -rf dist
	-rm -f mesos-calico.tar
	-docker rmi calico/mesos-calico:0.27.0-1
	-docker rmi calico/mesos-rpm-builder

help: # Some kind of magic from https://gist.github.com/rcmachado/af3db315e31383502660
	$(info Available targets)
	@awk '/^[a-zA-Z\-\_0-9]+:/ {                                   \
		nb = sub( /^## /, "", helpMsg );                             \
		if(nb == 0) {                                                \
			helpMsg = $$0;                                             \
			nb = sub( /^[^:]*:.* ## /, "", helpMsg );                  \
		}                                                            \
		if (nb)                                                      \
			printf "\033[1;31m%-" width "s\033[0m %s\n", $$1, helpMsg; \
	}                                                              \
	{ helpMsg = $$0 }'                                             \
	width=$$(grep -o '^[a-zA-Z_0-9]\+:' $(MAKEFILE_LIST) | wc -L)  \
	$(MAKEFILE_LIST)
