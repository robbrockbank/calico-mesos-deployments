# Using Calico Mesos
The following information includes application json and information on launching tasks in a Mesos Cluster with Calico.

## Test Cluster Health
Before you start launching tasks with Marathon, we suggest running the Calico-Mesos Test Framework. This Framework will register with mesos directly and launch ping and sleep tasks across your mesos cluster, verifiying netgroup enforcement and network connectivity between tasks.

To launch the framework, run the following docker command from any host that can communicate with your master (we recommend simply running it directly on the master itself):
```
docker run calico/calico-mesos-framework <master-ip>:5050
```
- Some tests require multiple hosts to ensure cross-host communication, and may fail unless you are running 2+ agents.
- Additionally, if running your cluster in the public cloud, cross-host tests will fail unless you [Enable IP over IP](https://github.com/projectcalico/calico-containers/blob/master/docs/FAQ.md#can-i-run-calico-in-a-public-cloud-environment)

Be sure to contact us on [Slack][calico-slack] if your tests are still not passing!

## Launching Tasks with Marathon
Calico is compatible with all frameworks which use the new NetworkInfo protobuf when launching tasks. Marathon has introduced limited support for this in v0.14.0. 

### Launching Marathon
If you haven't followed one of our guides which includes Marathon, quickly launch it with the following command:
```
docker run \
-e MARATHON_MASTER=zk://<ZOOKEEPER-IP>:2181/mesos \
-e MARATHON_ZK=zk://<ZOOKEEPER-IP>:2181/marathon \
-p 8080:8080 \
mesosphere/marathon:v0.14.0
```

### Launching Tasks
Marathon-v0.14.0 supports two new fields in an application's JSON file:

- `ipAddress`: Specifiying this field grants the application an IP Address networked by Calico.
- `group`: Groups are roughly equivalent to Calico Profiles. The default implementation isolates applications so they can only communicate with other applications in the same group. Assign a task the static `public` group to allow it to communicate with any other application.
 
> See [Marathon's IP-Per-Task documentation][marathon-ip-per-task-doc] for more information.

The Marathon UI does not yet include a field for specifiying NetworkInfo, so we'll use the command line to launch an app with Marathon's REST API. Below is a sample `app.json` file that is configured to receive an address from Calico:
```
{
    "id":"/calico-apps",
    "apps": [
        {
            "id": "hello-world-1",
            "cmd": "ip addr && sleep 30",
            "cpus": 0.1,
            "mem": 64.0,
            "ipAddress": {
                "groups": ["my-group-1"]
            }
        }
    ]
}
```

Send the `app.json` to marathon to launch it:
```
curl -X PUT -H "Content-Type: application/json" http://localhost:8080/v2/groups/calico-apps  -d @app.json
```
[calico-slack]: https://calicousers-slackin.herokuapp.com/
[marathon-ip-per-task-doc]: https://github.com/mesosphere/marathon/blob/v0.14.0/docs/docs/ip-per-task.md
[![Analytics](https://ga-beacon.appspot.com/UA-52125893-3/calico-containers/docs/mesos/README.md?pixel)](https://github.com/igrigorik/ga-beacon)
