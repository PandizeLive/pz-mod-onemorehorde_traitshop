import java.io.FileReader;
import java.io.IOException;
import java.io.Reader;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public final class KahluaSyntaxCheck {
    private KahluaSyntaxCheck() {
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            throw new IllegalArgumentException("Expected one Lua root path");
        }

        Path root = Path.of(args[0]);
        Class<?> compilerClass = Class.forName(
            "se.krka.kahlua.luaj.compiler.LuaCompiler");
        Class<?> tableClass = Class.forName("se.krka.kahlua.vm.KahluaTable");
        Method load = compilerClass.getMethod(
            "loadis", Reader.class, String.class, tableClass);
        List<Path> files = new ArrayList<>();
        try (var stream = Files.walk(root)) {
            stream.filter(path -> path.toString().endsWith(".lua"))
                .sorted(Comparator.naturalOrder())
                .forEach(files::add);
        }

        int failures = 0;
        for (Path file : files) {
            try (FileReader reader = new FileReader(file.toFile())) {
                load.invoke(null, reader, file.toString(), null);
            } catch (InvocationTargetException exception) {
                failures++;
                Throwable cause = exception.getCause();
                System.err.println(file + ": " + cause.getMessage());
            } catch (RuntimeException | IOException exception) {
                failures++;
                System.err.println(file + ": " + exception.getMessage());
            }
        }

        System.out.println((files.size() - failures) + "/" + files.size()
            + " Lua files passed Kahlua compilation");
        if (failures > 0) {
            System.exit(1);
        }
    }
}
