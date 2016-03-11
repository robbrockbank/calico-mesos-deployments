default: rpm 

## Create the calico-mesos RPM
rpm:
	mkdir -p -m 777 dist/rpm/
	docker build -t calico/mesos-rpm-builder ./packages
	docker run \
	-v `pwd`/dist/rpm/:/root/rpmbuild/RPMS/ \
	calico/mesos-rpm-builder

## Clean everything (including stray volumes)
clean:
	-rm -rf dist
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
