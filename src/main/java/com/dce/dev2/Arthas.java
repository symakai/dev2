package main.java.com.dce.dev2;


import java.util.HashSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


public class Arthas {

    private static HashSet<String> hashSet = new HashSet<String>();

    private static ExecutorService executorService = Executors.newFixedThreadPool(1);

    public static void main(String[] args) {
        // mock CPU high usage
        // mock block
        thread();
        // mock deadlock
        deadThread();

        addHashSetThread();
    }

    public static void addHashSetThread() {
        new Thread(() -> {
            int count = 0;
            while (true) {
                try {
                    hashSet.add("count" + count);
                    Thread.sleep(10000);
                    count++;
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }

    public static void cpu() {
        cpuHigh();
        cpuNormal();
    }

    private static void cpuHigh() {
        Thread thread = new Thread(() -> {
            while (true) {
                System.out.println("cpu high");
            }
        });
        executorService.submit(thread);
    }

    private static void cpuNormal() {
        for (int i = 0; i < 10; i++) {
            new Thread(() -> {
                while (true) {
                    System.out.println("cpu start");
                    try {
                        Thread.sleep(3000);
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }).start();
        }
    }

    /**
     * 模拟线程阻塞,向已经满了的线程池提交线程
     */
    private static void thread() {
        Thread thread = new Thread(() -> {
            while (true) {
                System.out.println("thread start");
                try {
                    Thread.sleep(3000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
            }
        });
        executorService.submit(thread);
    }

    /**
     * deadlock
     */
    private static void deadThread() {
        Object resourceA = new Object();
        Object resourceB = new Object();
        Thread threadA = new Thread(() -> {
            synchronized (resourceA) {
                System.out.println(Thread.currentThread() + " get A");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread() + " waiting B");
                synchronized (resourceB) {
                    System.out.println(Thread.currentThread() + "get B");
                }
            }
        });

        Thread threadB = new Thread(() -> {
            synchronized (resourceB) {
                System.out.println(Thread.currentThread() + " get B");
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException e) {
                    e.printStackTrace();
                }
                System.out.println(Thread.currentThread() + " waiting A");
                synchronized (resourceA) {
                    System.out.println(Thread.currentThread() + " get A");
                }
            }
        });
        threadA.start();
        threadB.start();
    }
}
