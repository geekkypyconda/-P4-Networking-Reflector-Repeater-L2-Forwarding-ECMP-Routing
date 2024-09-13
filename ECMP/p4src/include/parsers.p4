/*************************************************************************
*********************** P A R S E R  *******************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        //TODO 2: Define a parser for ethernet, ipv4 and tcp
       	
       	transition ethernetParser;
       	
    }

    state ethernetParser{
      packet.extract(hdr.ethernet);
      transition select(hdr.ethernet.etherType){
        TYPE_IPV4: ipv4Parser;
        default: accept;
      }
    }

    state ipv4Parser{
    	packet.extract(hdr.ipv4);
      transition select(hdr.ipv4.protocol){
        6: tcpParser;
        default: accept;
      } 
    }

    state tcpParser{
       	packet.extract(hdr.tcp);
       	transition accept;
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        //TODO 3: Deparse the ethernet, ipv4 and tcp headers
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
    }
}