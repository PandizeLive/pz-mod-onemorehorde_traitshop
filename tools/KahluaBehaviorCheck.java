import java.io.Reader;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;

public final class KahluaBehaviorCheck {
    public static void main(String[] args) throws Exception {
        Class<?> platformType = Class.forName("se.krka.kahlua.vm.Platform");
        Class<?> platformImpl = Class.forName("se.krka.kahlua.j2se.J2SEPlatform");
        Class<?> tableType = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Class<?> threadType = Class.forName("se.krka.kahlua.vm.KahluaThread");
        Object platform = platformImpl.getMethod("getInstance").invoke(null);
        Object env = platformImpl.getMethod("newTable").invoke(platform);
        tableType.getMethod("rawset", Object.class, Object.class)
            .invoke(env, "_G", env);
        Class.forName("se.krka.kahlua.stdlib.BaseLib")
            .getMethod("register", tableType).invoke(null, env);
        for (String library : new String[] { "stdlib.StringLib", "stdlib.TableLib",
                "stdlib.CoroutineLib", "j2se.MathLib" }) {
            Class.forName("se.krka.kahlua." + library)
                .getMethod("register", platformType, tableType)
                .invoke(null, platform, env);
        }
        Object thread = threadType.getConstructor(platformType, tableType)
            .newInstance(platform, env);
        threadType.getField("debugOwnerThread").set(thread, Thread.currentThread());
        Method compile = Class.forName("se.krka.kahlua.luaj.compiler.LuaCompiler")
            .getMethod("loadis", Reader.class, String.class, tableType);
        Method call = threadType.getMethod("call", Object.class, Object[].class);
        Method get = tableType.getMethod("rawget", Object.class);
        Method set = tableType.getMethod("rawset", Object.class, Object.class);
        Class<?> functionType = Class.forName("se.krka.kahlua.vm.JavaFunction");
        Object roundTrip = java.lang.reflect.Proxy.newProxyInstance(functionType.getClassLoader(), new Class<?>[] {functionType}, (proxy, method, values) -> {
            if (!method.getName().equals("call")) return null;
            Object frame = values[0];
            Object source = frame.getClass().getMethod("get", int.class).invoke(frame, 0);
            java.io.ByteArrayOutputStream bytes = new java.io.ByteArrayOutputStream();
            tableType.getMethod("save", java.io.DataOutputStream.class).invoke(source, new java.io.DataOutputStream(bytes));
            Object restored = platformImpl.getMethod("newTable").invoke(platform);
            tableType.getMethod("load", java.io.DataInputStream.class, int.class).invoke(restored,
                new java.io.DataInputStream(new java.io.ByteArrayInputStream(bytes.toByteArray())), 249);
            frame.getClass().getMethod("push", Object.class).invoke(frame, restored);
            return 1;
        });
        set.invoke(env, "nativeRoundTrip", roundTrip);
        for (String arg : args) {
            int split = arg.indexOf('=');
            String name = arg.substring(0, split);
            Path path = Path.of(arg.substring(split + 1));
            try (Reader reader = Files.newBufferedReader(path)) {
                Object chunk = compile.invoke(null, reader, path.toString(), env);
                Object result = call.invoke(thread, chunk, new Object[0]);
                if (!name.equals("_")) {
                    Object modules = get.invoke(env, "__modules");
                    set.invoke(modules, name, result);
                }
            } catch (InvocationTargetException error) {
                System.err.println("Stage: " + get.invoke(env, "testStage")
                    + "; assertion: " + get.invoke(env, "testFailure"));
                throw new IllegalStateException(path.toString(), error.getCause());
            }
        }
        Object packets = get.invoke(env, "testTransportPackets");
        if (packets != null) {
            int count = ((Number)tableType.getMethod("len").invoke(packets)).intValue();
            java.nio.ByteBuffer buffer = java.nio.ByteBuffer.allocate(60000);
            Class<?> writerType = Class.forName("zombie.core.network.ByteBufferWriter");
            Object writer = writerType.getConstructor(java.nio.ByteBuffer.class).newInstance(buffer);
            Method save = Class.forName("zombie.network.TableNetworkUtils").getMethod("save", tableType, writerType);
            int maximum = 0;
            for (int index = 1; index <= count; index++) {
                buffer.clear();
                save.invoke(null, get.invoke(packets, Double.valueOf(index)), writer);
                maximum = Math.max(maximum, buffer.position());
            }
            System.out.println("Native B42.20.4 packets=" + count + "; largest=" + maximum + " bytes (limit 60000)");
        }
        Object exported = get.invoke(env, "testExport");
        if (exported instanceof String && System.getProperty("p1.output") != null) {
            Files.writeString(Path.of(System.getProperty("p1.output")), (String)exported);
        }
        Object output = get.invoke(env, "testOutput");
        if (output instanceof String) System.out.println(output);
        System.out.println("Kahlua behavior assertions passed");
    }
}
