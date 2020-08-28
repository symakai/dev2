package jvm;

/**
 * Jstat
 */
public class Jstat {

    public static void main(String[] args) {
        for (int i = 0; i < Integer.MAX_VALUE; i++) {
            byte[] b1 = new byte[1024 * 1024];
            byte[] b2 = new byte[1024 * 1024];
            byte[] b3 = new byte[1024 * 1024];
            byte[] b4 = new byte[1024 * 1024];
            byte[] b5 = new byte[1024 * 1024];
            byte[] b6 = new byte[1024 * 1024];
            b3 = null;
            b5 = null;
            b6 = null;
        }
    }
}