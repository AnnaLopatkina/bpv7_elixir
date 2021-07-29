# Bpv7
A Bundle Protocol node which accepts and forwards Bundle Protocol v7 Bundles.

## Usage
After Downloading the repository all dependencies have to be downloaded and installed.
This can be done by 
```mix deps.get```

After that the application can be started by 
```mix run --no-halt```

With the default settings the node is now accepting Bundles at port 4040.
The Port can be changed by the environment variable `PORT`.
For example `PORT=4040 mix run --no-halt`

To be able to forward Bundle the node need to know how it can reach Nodes for specific EIDs.
The configuration is done via a simple tcp Session on Port 4041 which can used for example with telnet.

The Config has the format `<EID>,<host>,<port>,<availability_begin>,<availability_end>`.
A configuration process may be look like this:
```
$ telnet localhost 4041
Trying 127.0.0.1...
Connected to localhost.
Escape character is '^]'.
//c.dtn/bundlesink,localhost,4224,2021-07-27T17:06:35Z,2021-07-27T17:06:55Z
``` 

Bundles can be produced by the usage of the [pyD3TN python Tooling](https://pypi.org/project/pyD3TN/) with this short snippet:
```python
from pyd3tn.bundle7 import CRCType
from pyd3tn.bundle7 import serialize_bundle7
from pyd3tn.mtcp import MTCPConnection

bundle = serialize_bundle7("dtn://a.dtn","dtn://c.dtn/bundlesink",b"Hello World!",crc_type_canonical=CRCType.CRC32)
with MTCPConnection('127.0.0.1', 4040) as conn:
        conn.send_bundle(bundle)
```
