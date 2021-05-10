# Testsetup
0.   Build python-tools container

      ```
      docker build -f ud3tn-python-tools --tag python-ud3tn-tools .
      ```

1.   start Bpv7 Nodes

      ```
      docker-compose up -d
      ```

2.   Configure contact between node

      ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_config.py \
      --tcp ud3tn-node 4242 \
      --dest_eid dtn://ud3tn-node.dtn \
      --schedule 1 3600 100000 \
      dtn://node2.dtn mtcp:node2:4225
      ```
	  
	  PowerShell:
	  
	  ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_config.py `
      --tcp ud3tn-node 4242 `
      --dest_eid dtn://ud3tn-node.dtn `
      --schedule 1 3600 100000 `
      dtn://node2.dtn mtcp:node2:4225
      ```

3.   Attach receiver

      ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_receive.py \
      --tcp node2 4243 \
      --agentid bundlesink
      ```
	  
	  PowerShell:
	  
	  ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_receive.py `
      --tcp node2 4243 `
      --agentid bundlesink
      ```

4.   Send bundle

      ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_send.py \
      --tcp ud3tn-node 4242 \
      dtn://node2.dtn/bundlesink \
      'Hello, world!'
      ```
	  
	  PowerShell:
	  
	  ```
      docker run -it --network testsetup_bpv7 python-ud3tn-tools python aap_send.py `
      --tcp ud3tn-node 4242 `
      dtn://node2.dtn/bundlesink `
      'Hello, world!'
      ```

