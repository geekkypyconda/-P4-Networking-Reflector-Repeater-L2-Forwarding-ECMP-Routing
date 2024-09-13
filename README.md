# -P4-Networking-Reflector-Repeater-L2-Forwarding-ECMP-Routing

# Repeater

## Introduction

In the second introductory exercise we will use our first table and conditional
statements in a control block. In this exercise you will make a two-port
switch act as a packet repeater, in other words, when a packet enters `port 1`
it has to be leave from `port 2` and vice versa.

<p align="center">
<img src="images/topology.png" title="Repeater Topology">
<p/>

## Before Starting

As we already did in the previous exercise we provide you some files that will
help you through the exercise.

  *  `p4app.json`: describes the topology we want to create with the help
     of mininet and p4-utils package.
  *  `send.py`: script to send packets.
  *  `receive.py`: script to receive packets.
  *  `repeater.p4`: p4 program skeleton to use as a starting point.

Again all these files are enough to start the topology. However packets will
not flow through the switch until you complete the p4 code.

To test if your repeater works you can use `send.py` and `receive.py`. Send just sends a single
packet to the destination address you pass as a parameter. Receive prints the content of each
received packet.

#### Note about p4app.json

If you have a look at the `p4app.json` file we provide you, at the bottom you can find
the description of the topology used in this exercise:

```javascript
"topology": {
    "assignment_strategy": "l2",
    "links": [
        ["h1", "s1"],
        ["h2", "s1"]
    ],
    "hosts": {
        "h1": {},
        "h2": {}
    },
    "switches": {
        "s1": {}
    }
}
```

The topology object describes hosts, switches and how they are connected.
In order to assist us even further when creating a topology an `assignment_strategy`
can be chosen. For this exercise we decided to use `l2`. This means that all the devices composing
the topology are assumed to belong to the same subnetwork. Therefore hosts get automatically assigned
with IPs belonging to the same subnet (starting from `10.0.0.1/16`). Furthermore, and unless disabled,
`p4-utils` will automatically populate each host's ARP table with the MAC addresses of all the other hosts.

For example, after starting the topology, `h1` arp table is already loaded with h2's MAC address:

<img src="images/arp_example.png" title="Repeater Topology">

> Automatically populating the ARP Table is needed because our switches do
> not know how to broadcast packets something strictly needed during the Address Resolution.

You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://github.com/nsg-ethz/p4-utils#topology-description).

## Implementing the Packet Repeater

To solve this exercise you only need to fill the gaps you will find in the
`repeater.p4` skeleton. The places where you are supposed to write your own code
are marked with a `TODO`. You will have to solve this exercise using two
different approaches (for the sake of learning). First, and since the switch
only has 2 ports you will have to solve the exercise by just using conditional statements
and fixed logic. For the second solution, you will have to use a match-action table and
populate it using the CLI.

### Using Conditional Statements

1. Using conditional statements, write (in the `MyIngress` Control Block) the logic
needed to make the switch act as a repeater. (only `TODO 3`)

### Using a Table

> If for the second solution you want to use a different program name and
> and topology file you can just define a new `p4` file and a different `.json`
> topology configuration, then you can run `sudo p4run --config <json file name>`.

1. Define a table of size 2, that matches packet's ingress_port and uses that
to figure out which output port needs to be used (following the definition of repeater).

2. Define the action that will be called from the table. This action needs to set the output port. The
type of `ingress_port` is `bit<9>`. For more info about the `standard_metadata` fields see:
the [`v1model.p4`](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4) interface.

3. Call (by using `apply`), the table you defined above.

4. Populate the table (using CLI or writing the commands in a file). For more information
about table population check the following [documentation](../../documentation/control-plane.md).

## Testing your solution

Once you have the `repeater.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).

   ```bash
   sudo p4run
   ```

2. Get a terminal in `h1` and `h2` using `mx`:

   ```bash
   mx h1
   mx h2 #in different terminal windows
   ```

   Or directly from the mininet prompt using `xterm`:

   ```bash
   > mininet xterm h1 h2
   ```


3. Run `receive.py` app in `h2`.

4. Run `send.py` in `h1`:

   ```bash
   python send.py 10.0.0.2 "Hello H2"
   ```

   The output at `h2` should be:

   <img src="images/h2_output.png" title="Receive Output">

5. Since the switch will always forward traffic from `h1` to `h2` and vice versa, we can test
the repeater with other applications such as: `ping`, `iperf`, etc. The mininet CLI provides some helpers
that make very easy such kind of tests:

   ```bash
   > mininet h1 ping h2
   ```

   ```bash
   > mininet iperf h1 h2
   ```

#### Some notes on debugging and troubleshooting

You should not have had any trouble with these first introductory exercises. However, as things get
more complicated you will most likely need to debug your programs and the behaviour of the switch and network.

We have added a [small guideline](../../documentation/debugging-and-troubleshooting.md) in the documentation section. Use it as a reference when things do not work as
expected.


# L2 Basic Forwarding

## Introduction

In today's first exercise we will implement a very basic layer 2 forwarding switch. In order to
tell the switch how to forward frames, the switch needs to know in which port it can find a given MAC
address (hosts). Real life switches automatically learn this mapping by using the l2 learning algorithm (we will see
this later today). In order to familiarize ourselves with tables and how to map ethernet addresses to a given host (port)
we will implement a very basic l2 forwarding that statically maps mac addresses to ports.

<p align="center">
<img src="images/l2_topology.png" title="L2 Star Topology">
<p/>

## Before Starting

As we already did in the previous exercises we provide you some files that will
help you through the exercise.

  *  `p4app.json`: describes the topology we want to create with the help
     of mininet and p4-utils package.
  *  `p4src/l2_basic_forwarding.p4`: p4 program skeleton to use as a starting point.


**Note**: This time you will not be able to run `p4run` until you finish some of the `TODOs`.

#### Notes about p4app.json

Remember that if the `l2` assignment strategy is enabled all devices will be automatically placed in the same
subnet and ARP tables get automatically populated. This was already explained in the previous exercise session, for
more information check [here](../02-Repeater/README.md#note-about-p4appjson).

In this exercise you will need to fill some table entries as we did last week.
If you used the control plane documentation page to fill tables, you probably used
the `simple_switch_CLI` and filled the table manually. Since this can get a bit repetitive, p4-utils allows
you to define a `CLI-like` input file for each switch. If you open the `p4app.json` example file provided with
this exercise, you will see that now, the `s1` switch has an extra option, `cli_input = ''s1-commands.txt''`.
Every time you start the topology, or reboot the switch using the `cli`, p4-utils will automatically call
the `simple_switch_CLI` using that file.

You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://github.com/nsg-ethz/p4-utils#topology-description).

## Implementing the L2 Basic Forwarding

To solve this exercise you only need to fill the gaps that you will find in the
`l2_basic_forwarding.p4` skeleton. The places where you are supposed to write your own code
are marked with a `TODO`. Furthermore, you will need to create a file called `s1-commands.txt`
with commands to fill your tables.

In summary, your tasks are:

1. Define the ethernet header type and an empty metadata `struct` called meta. Then define
the headers `struct` with an ethernet header.

2. Parse the ethernet header.

3. Define a match-action table to make switch behave as a l2 packet forwarder. The destination
Mac address of each packet should tell the switch which output port use. You can use your last exercise
as a reminder, or check the [documentation](../../documentation/control-plane.md).

4. Define the action the table will call for matching entries. The action should get
the output port index as a parameter and set it to the `egress_spec` switch's metadata field.

5. Apply the table you defined.

6. Deparse the ethernet header to add it back to the wire.

7. Write the `s1-commands.txt` file. This file should contain all the `cli` commands needed to fill
the forwarding table you defined in 3. For more information about adding entries to the table check the
[control plane documentation](../../documentation/control-plane.md).

   **Important Note**: In order to fill the table you will need two things:

     1. Host's MAC addresses: by default hosts get assigned MAC addresses using the following pattern: `00:00:<IP address to hex>`. For example
     if `h1` IP's address were `10.0.1.5` the Mac address would be: `00:00:0a:00:01:05`. Alternatively, you can use `iconfig`/`ip` directly in a
     host's terminal.

     2. Switch port index each host is connected to. There are several ways to figure out the `port_index` to interface mapping. By default
     p4-utils add ports in the same order they are found in the `links` list in the `p4app.json` conf file. Thus, with the current configuration
     the port assignment would be: {h1->1, h2->2, h3->3, h4->4}. However, this basic port assignment might not hold for more complex topologies. Another
     way of finding out port mappings is checking the messages printed by when running the `p4run` command:

         ```bash
         Switch port mapping:
         s1:  1:h1       2:h2    3:h3    4:h4
         ```

        In future exercises we will see an extra way to get topology information.

## Testing your solution

Once you have the `l2_basic_forwarding.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).

   ```bash
   sudo p4run
   ```

2. Ping between all hosts using the cli:

   ```bash
   *** Starting CLI:
   mininet> pingall
   *** Ping: testing ping reachability
   h1 -> h2 h3 h4
   h2 -> h1 h3 h4
   h3 -> h1 h2 h4
   h4 -> h1 h2 h3
   *** Results: 0% dropped (12/12 received)
   mininet>
   ```

#### Some notes on debugging and troubleshooting

We have added a [small guideline](../../documentation/debugging-and-troubleshooting.md) in the documentation section. Use it as a reference when things do not work as
expected.


# Equal-Cost Multi-Path Routing

## Introduction

In this exercise  we will implement a layer 3 forwarding switch that is able to load balance traffic
towards a destination across equal cost paths. To load balance traffic across multiple ports we will implement ECMP (Equal-Cost
Multi-Path) routing. When a packet with multiple candidate paths arrives, our switch should assign the next-hop by hashing some fields from the
header and compute this hash value modulo the number of possible equal paths. For example in the topology below, when `s1` has to send
a packet to `h2`, the switch should determine the output port by computing: `hash(some-header-fields) mod 4`. To prevent out of order packets, ECMP hashing is done on a per-flow basis,
which means that all packets with the same source and destination IP addresses and the same source and destination
ports always hash to the same next hop.

<p align="center">
<img src="images/multi_hop_topo.png" title="Multi Hop Topology"/>
<p/>

For more information about ECMP see this [page](https://docs.cumulusnetworks.com/display/DOCS/Equal+Cost+Multipath+Load+Sharing+-+Hardware+ECMP)

## Before Starting

As usual, we provide you with the following files:

  *  `p4app.json`: describes the topology we want to create with the help
     of mininet and p4-utils package.
  *  `p4src/ecmp.p4`: p4 program skeleton to use as a starting point.
  *  `p4src/includes`: In today's exercise we will split our p4 code in multiple files for the first time. In the includes
  directory you will find `headers.p4` and `parsers.p4` (which also have to be completed).
  *  `send.py`: a small python script to generate multiple packets with different tcp port.

#### Notes about p4app.json

For this exercise (and next one) we will use a new IP assignment strategy. If you have a look at `p4app.json` you will see that
the option is set to `mixed`. Therefore, only hosts connected to the same switch will be assigned to the same subnet. Hosts connected
to a different switch will belong to a different `/24` subnet. If you use the namings `hX` and `sX` (e.g h1, h2, s1...), the IP assignment
goes as follows: `10.x.x.y`. Where `x` is the switch id (upper and lower bytes), and `y` is the host id. For example, in the topology above,
`h1` gets `10.0.1.1` and `h2` gets `10.0.6.2`.
 
You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://github.com/nsg-ethz/p4-utils#topology-description).

## Implementing the L3 forwarding switch + ECMP

To solve this exercise we have to program our switch such that is able to forward L3 packets when there is one
possible next hop or more. For that we will use two tables: in the first table we match the destination IP and
depending on whether ECMP has to be applied (for that destination) we set the output port or a ecmp_group. For the later we
will apply a second table that maps (ecmp_group, hash_output) to egress ports.

This time you will have to fill the gaps in several files: `p4src/ecmp.p4`, `p4src/include/headers.p4`
and `p4src/include/parsers.p4`. Additionally, you will have to create a `cli` command file for each switch and name them
`sX-commands.txt` (see inside the `p4app.json`).

To successfully complete the exercise you have to do the following:

1. Use the header definitions that are already provided.

2. Define the parser that is able to parse packets up to `tcp`. Note that for simplicity we do not consider `udp` packets
in this exercise. This time you must define the parser in: `p4src/include/parsers.p4`.

3. Define the deparser. Just emit all the headers in the right order.

4. Define a match-action table that matches the IP destination address of every packet and has three actions: `set_nhop`, `ecmp_group`, `drop`.
Set the drop action as default.

5. Define the action `set_nhop`. This action takes 2 parameters: destination mac and egress port.  Use the parameters to set the destination mac and
`egress_spec`. Set the source mac as the previous destination mac (this is not what a real L3 switch would do, we just do it for simplicity). In a more realistic implementation we would create a table
that maps egress_ports to each switch interface mac address, however since the source mac address is not very important for this exercise just do this swap). When sending packets from a switch to another switch, the destination
address is not very important, and thus you can use a random one. However, keep in mind that when the packet is sent to a host needs to have the right destination MAC address.
Finally, decrease the packet's TTL by 1. **Note:** since we are in a L3 network, when you send packets from `s1` to `s2` you have to use the dst mac of the switch interface not the mac address of the receiving host, that instead
is done in the very last hop. Finally, decrease the packet's TTL by 1.

6. Define the action `ecmp_group`. This action takes two parameters, the ecmp group id (14 bits), and the number of next hops (16 bits). This
action is one of the key parts of the ECMP algorithm. You have to do several things:

   1. In this action we will compute a hash function. To store the output you need to define a metadata field. Define `ecmp_hash` (14 bits) inside
   the metadata struct in `headers.p4`. Use the `hash` extern function to compute the hash of packets 5-tuple (src ip, dst ip, src port, dst port, protocol). The signature of a hash function is:
   `hash(output_field, (crc16 or crc32), (bit<1>)0, {fields to hash}, (bit<16>)modulo)`.
   2. Define another metadata field and call it `ecmp_group_id` (14 bits).
   3. Finally copy the value of the second action parameter ecmp group in the metadata field you just defined (`ecmp_group_id`) this will be used
   to match in the second table.

**Note**: a lot of people asked why the`ecmp_group_id` is needed. In few words, it allows you to map from one ip address to a set of ports, which does not have to be
the 4 ports we use in this exercise. For example, you could have that for `IP1` you use only the upper 2 ports and for `IP2` you loadbalance using the two lower ports. Thus, by
creating two ecmp groups you can easily map any destination address to any set of ports.

7. Define the second match-action table used to set `ecmp_groups` to real next hops. The table should have `exact` matches to the metadata fields
your defined in the previous step. Thus, it should match to the `meta.ecmp_group_id` and then to the output of the hash function `meta.ecmp_hash` (which will be
a value ranging from 0 to `NUM_NEXT_HOPS-1`). A match in this table should call the `set_nhop` action that you already defined above, a miss should mark the packet
to be dropped (set `drop` as default action).  This enables us to use any subset of interfaces. For example imagine that
in the topology above we have `h2` and `h3` ( h3 does not exist, but just for the sake of the example) we could define two different `ecmp` groups (in the previous table), one that maps to port 2 and 4, and
one that maps to port 3 and 5. And then in this table we could add two rules per group, to make the outputs `[0,1]` from the hash function match [2,4] and `[3,5]`
respectively.

8. Define the ingress control logic:

    1. Check if the ipv4 header was parsed (use `isValid`).
    2. Apply the first table.
    3. If the action `ecmp_group` was called during the first table apply. Call the second table.
    Note: to know which action was called during an apply you can use a switch statement and `action_run`, to see more information about how to check which action was used, check out
    the [P4 16 specification](https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html#sec-invoke-mau)

9. In this exercise we modify a packet's field for the first time (remember we have to subtract 1 to the ip.ttl field). When doing so, the `ipv4` checksum field need
to be updated otherwise other network devices (or receiving hosts) might drop the packet. To do that, the `v1model` provides an `extern` function that can be called
inside the `MyComputeChecksum` control to update checksum fields. In this exercise, you do not have to do anything, however just go to the `ecmp.p4` file and check how
the `update_checksum` is used.

10. This time you have to write six `sX-commands.txt` files, one per switch. Note that only `s1` and `s6` need to have `ecmp` groups installed. For all
the other switches setting rules for the first table (using action `set_nhop`) will suffice. For `s1` you have to set a direct next hop towards `h1`, and a ecmp
group towards `h2`. Set the ecmp group with `id = 1` and `num_hops = 4`. Then define 4 rules that map from 0 to 3 to one of the 4 switch output ports 
(using the second table).

## Testing your solution

Once you have the `ecmp.p4` program finished (and all the `commands.txt` files) you can test its behaviour:

1. Start the topology (this will also compile and load the program).

   ```bash
   sudo p4run
   ```

2. Check that you can ping:

   ```bash
   > mininet pingall
   ```

3. Monitor the 4 links from `s1` that will be used during `ecmp` (from `s1-eth2` to `s1-eth5`). Doing this you will be able to check which path is each flow
taking.

   ```bash
   sudo tcpdump -enn -i s1-ethX
   ```

4. Ping between two hosts:

   You should see traffic in only 1 or 2 interfaces (due to the return path).
   Since all the ping packets have the same 5-tuple.

5. Do iperf between two hosts:

   You should also see traffic in 1 or 2 interfaces (due to the return path).
   Since all the packets belonging to the same flow have the same 5-tuple, and thus the hash always returns the same index.

6. Get a terminal in `h1`. Use the `send.py` script.

   ```bash
   python send.py 10.0.6.2 1000
   ```

   This will send `tcp syn` packets with random ports. Now you should see packets going to all the interfaces, since each packet will have a different hash.

#### Some notes on debugging and troubleshooting

We have added a [small guideline](../../documentation/debugging-and-troubleshooting.md) in the documentation section. Use it as a reference when things do not work as
expected.
