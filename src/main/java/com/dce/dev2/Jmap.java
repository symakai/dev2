package main.java.com.dce.dev2;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Jmap
 */
public class Jmap {

    public static void main(String[] args) {
        List<String> list = new ArrayList<>();
        Random ra = new Random();
        String base = "base"; 
        for (int i = 0; i < Integer.MAX_VALUE; i++) {
            String val = base + String.valueOf(ra.nextInt(i + 1));
            list.add(val); 
            try {
                Thread.sleep(5);
            } catch (Exception e) {
                //TODO: handle exception
            }
        }
    }
}