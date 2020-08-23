package main.java.com.dce.dev2.jvm;

/**
 * Xss
 */
public class Xss {
    private static int count = 0;
    public static void recursion(long a, long b, long c) {
        long e = 1;
        long f = 2;
        long g = 3;
        long h = 4;
        long i = 5;
        long j = 6;
        long k = 7;
        long l = 8;
        long m = 9;
        count++;
        recursion(a, b, c);
    }
    public static void main(String[] args) {
        try {
            Xss.recursion(1, 2, 3);
        } catch (Throwable e) {
            System.out.println("call = " + Xss.count);
            e.printStackTrace();
        }
    }
}