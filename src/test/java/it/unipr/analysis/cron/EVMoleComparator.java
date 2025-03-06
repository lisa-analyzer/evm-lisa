package it.unipr.analysis.cron;

import it.unipr.EVMLiSA;
import it.unipr.cfg.EVMCFG;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.junit.Test;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class EVMoleComparator {
    private static final Logger log = LogManager.getLogger(EVMoleComparator.class);

    /*
       Contract: 0x903fa079b93d2bb222eafcf1f59d0a9b628d354a
     */
    @Test
    public void testComparator() throws Exception {
        int stackSize = 64;
        int stackSetSize = 1000;

        String bytecode = "0x608060405234801561001057600080fd5b50600436106100575760003560e01c80633659cfe61461005c5780635c60da1b14610084578063715018a6146100a85780638da5cb5b146100b0578063f2fde38b146100b8575b600080fd5b6100826004803603602081101561007257600080fd5b50356001600160a01b03166100de565b005b61008c610192565b604080516001600160a01b039092168252519081900360200190f35b6100826101a1565b61008c61025f565b610082600480360360208110156100ce57600080fd5b50356001600160a01b031661026e565b6100e6610388565b6001600160a01b03166100f761025f565b6001600160a01b031614610152576040805162461bcd60e51b815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572604482015290519081900360640190fd5b61015b8161038c565b6040516001600160a01b038216907fbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b90600090a250565b6001546001600160a01b031690565b6101a9610388565b6001600160a01b03166101ba61025f565b6001600160a01b031614610215576040805162461bcd60e51b815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572604482015290519081900360640190fd5b600080546040516001600160a01b03909116907f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0908390a3600080546001600160a01b0319169055565b6000546001600160a01b031690565b610276610388565b6001600160a01b031661028761025f565b6001600160a01b0316146102e2576040805162461bcd60e51b815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e6572604482015290519081900360640190fd5b6001600160a01b0381166103275760405162461bcd60e51b81526004018080602001828103825260268152602001806103f36026913960400191505060405180910390fd5b600080546040516001600160a01b03808516939216917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e091a3600080546001600160a01b0319166001600160a01b0392909216919091179055565b3b151590565b3390565b61039581610382565b6103d05760405162461bcd60e51b81526004018080602001828103825260338152602001806104196033913960400191505060405180910390fd5b600180546001600160a01b0319166001600160a01b039290921691909117905556fe4f776e61626c653a206e6577206f776e657220697320746865207a65726f20616464726573735570677261646561626c65426561636f6e3a20696d706c656d656e746174696f6e206973206e6f74206120636f6e7472616374a26469706673582212200cade1999456e1752d1142664807affc23f7965ebb666ca1dd9a308ec38ef69564736f6c63430007060033";
        String edgesEVMole = "[(0, 16), (0, 12), (16, 87), (16, 26), (26, 92), (26, 43), (43, 132), (43, 54), (54, 168), (54, 65), (65, 176), (65, 76), (76, 184), (76, 87), (92, 114), (92, 110), (114, 222), (132, 402), (168, 417), (176, 607), (184, 206), (184, 202), (206, 622), (222, 904), (230, 607), (247, 338), (247, 262), (338, 908), (347, 130), (402, 140), (417, 904), (425, 607), (442, 533), (442, 457), (533, 130), (607, 140), (607, 247), (607, 442), (607, 647), (622, 904), (630, 607), (647, 738), (647, 662), (738, 807), (738, 753), (807, 130), (898, 917), (904, 230), (904, 425), (904, 630), (908, 898), (917, 976), (917, 922), (976, 347)]";

        List<Long[]> evmole = parseLongArrayList(edgesEVMole);
        List<Long[]> evmlisa = new EVMLiSA().computeBasicBlocks(bytecode, stackSize, stackSetSize);

        log.info("Bytecode: {}", bytecode);
        log.info("stack size: {}", stackSize);
        log.info("stack set size: {}", stackSetSize);

        compareLists(evmlisa, evmole);
    }

    public static void compareLists(List<Long[]> evmlisa, List<Long[]> evmole) {
        Set<String> setEvmole = new HashSet<>();
        Set<String> setEvmlisa = new HashSet<>();

        log.debug("EVMLiSA bb: {}", EVMCFG.bbToString(evmlisa));
        log.debug("EVMole bb: {}", EVMCFG.bbToString(evmole));

        for (Long[] arr : evmole) {
            setEvmole.add(Arrays.toString(arr));
        }
        for (Long[] arr : evmlisa) {
            setEvmlisa.add(Arrays.toString(arr));
        }

        for (String arr : setEvmlisa) {
            if (!setEvmole.contains(arr)) {
                System.out.println("Missing in evmole: " + arr);
            }
        }
        for (String arr : setEvmole) {
            if (!setEvmlisa.contains(arr)) {
                System.out.println("Missing in evmlisa: " + arr);
            }
        }

        log.debug("EVMLiSA edges: {}", setEvmlisa.size());
        log.debug("EVMole edges: {}", setEvmole.size());
    }

    public List<Long[]> parseLongArrayList(String input) {
        List<Long[]> result = new ArrayList<>();
        Pattern pattern = Pattern.compile("\\((\\d+),\\s*(\\d+)\\)");
        Matcher matcher = pattern.matcher(input);

        while (matcher.find()) {
            long first = Long.parseLong(matcher.group(1));
            long second = Long.parseLong(matcher.group(2));
            result.add(new Long[]{first, second});
        }

        return result;
    }
}
