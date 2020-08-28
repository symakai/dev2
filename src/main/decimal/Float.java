package decimal;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * comment
 *
 * @author  xx
 */
public class Float {

    public static double round(double value, int places) {
        if (places < 0) {
            throw new IllegalArgumentException();
        }
        // long factor = (long)Math.pow(10, places);
        // value = value * factor;
        // long tmp = Math.round(value);
        // return (double)tmp / factor;
        BigDecimal bd = BigDecimal.valueOf(value);
        bd = bd.setScale(places, RoundingMode.HALF_UP);
        return bd.doubleValue();
    }

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

    void accuracy_scale() {
        double base = 0.1;
        double sum = 0.0;
        for (long i = 0; i < 1000000000L; i++) {
            sum += base;
            sum = round(sum, 2);
        }
        System.out.printf("sum:%.6f\n", sum);
        System.out.printf("sum:%.6f\n", round(sum, 6));

    }

    void bigUse() {
        System.out.println(new BigDecimal(1.03).subtract(new BigDecimal(0.41)));
        System.out.println(new BigDecimal("1.03").subtract(new BigDecimal("0.41")));
    }

    public static void main(String[] args) {
        Float obj = new Float();
        // obj.perf();
        obj.accuracy_scale();
        // obj.bigUse();
    }
}
