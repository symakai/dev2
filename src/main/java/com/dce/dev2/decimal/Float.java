package java.com.dce.dev2.decimal;
import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * comment
 *
 * @author  xx
 */
public class Float {
    void perf() {
        final long iterations = 10000000;
        long t = System.currentTimeMillis();
        double d = 123.456;
        for (int i = 0; i < iterations; i++) {
            final double curTime = (double)(System.currentTimeMillis());
            final double b = d * (curTime + curTime) / 3.1415;
        }

        System.out.println("double: " + (System.currentTimeMillis() - t));

        t = System.currentTimeMillis();
        BigDecimal bd = new BigDecimal("123.456");
        for (int i = 0; i < iterations; i++) {
            final BigDecimal b = bd.multiply(
                BigDecimal.valueOf(System.currentTimeMillis()).add(
                BigDecimal.valueOf(System.currentTimeMillis()))).divide(
                BigDecimal.valueOf(3.1415), 6, RoundingMode.HALF_UP);
        }
        System.out.println("java.math.BigDecimal: " + (System.currentTimeMillis() - t));
    }
    public static void main(String[] args) {
        Float obj = new Float();
        obj.perf();
    }
}
