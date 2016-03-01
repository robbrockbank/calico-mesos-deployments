# Copyright 2015 Metaswitch Networks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For details and docs - see https://github.com/phusion/baseimage-docker#getting_started

FROM djosborne/netmodules

############
## Calico ##
############
ADD packages/sources/modules.json /calico/
ADD https://github.com/projectcalico/calico-mesos/releases/download/v0.1.3/calico_mesos /calico/calico_mesos
RUN chmod +x /calico/calico_mesos
