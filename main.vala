
using Gst;
using Gdk;

/*
Camara/
    2017/
        4/
            13/
                1.png
                2.png
                etc...
*/


public class Camara : GLib.Object{

    // Toma una serie de fotografias

    private dynamic Gst.Pipeline player;
    private static Gst.Bus bus;
    private static GLib.MainLoop loop = new MainLoop();

    private static string BASE_PATH;

    private static int CURRENT_HOUR = 0;        //Cuando cambia la hora, cambia el path
    private static string CURRENT_PATH;         //Directorio donde se guardan los archivos
    private static string CURRENT_FILE_NAME;    //Nombre sin extension del archivo actual

    public Camara(){

        check_base_path_exists();

        player = new Gst.Pipeline("Camara");
        Gst.Element camara = Gst.ElementFactory.make("v4l2src", "v4l2src");
        Gst.Element videoconvert = Gst.ElementFactory.make("videoconvert", "videoconvert");
        Gst.Element gdkpixbufsink = Gst.ElementFactory.make("gdkpixbufsink", "gdkpixbufsink");
        bus = player.get_bus(); bus.add_watch(100, sync_message);

        //camara.set("device", "/dev/video1");

        player.add(camara); player.add(videoconvert); player.add(gdkpixbufsink);
        camara.link(videoconvert); videoconvert.link(gdkpixbufsink);

        player.set_state(Gst.State.PLAYING);

        GLib.stdout.printf("Process Id: %i\n", Posix.getpid());
        GLib.stdout.flush();
        loop.run();
    }

    private bool sync_message(Gst.Bus bus, Gst.Message message){
        switch(message.type){
            case Gst.MessageType.ERROR:
                GLib.Error err; string debug;
                message.parse_error(out err, out debug);
                GLib.stdout.printf("Error: %s\n", err.message);
                GLib.stdout.flush(); loop.quit(); break;
            default:
                if (message.get_structure().get_name() == "pixbuf"){
                    get_pixbuf();}
                break;}
        return true;
        }

    private void check_base_path_exists(){
        string home = GLib.Environment.get_variable("HOME");
        BASE_PATH = GLib.Path.build_filename(home, "Camara");
        GLib.File file = GLib.File.new_for_path(BASE_PATH);
        if (file.query_exists() != true){file.make_directory();}
    }

    private void set_path_dir_and_file_path(){
        Gst.DateTime time = new Gst.DateTime.now_local_time();
        int anio = time.get_year(); int mes = time.get_month();
        int dia = time.get_day(); int hora = time.get_hour();
        //int minuto = time.get_minute(); int segundo = time.get_second();

        if (hora != CURRENT_HOUR){
            CURRENT_HOUR = hora;

            string day_dir_name = dia.to_string() + "-" + mes.to_string() + "-" + anio.to_string();

            string day_path = GLib.Path.build_filename(BASE_PATH, day_dir_name);
            GLib.File file = GLib.File.new_for_path(day_path);
            if (file.query_exists() != true){file.make_directory();}

            CURRENT_PATH = GLib.Path.build_filename(day_path, CURRENT_HOUR.to_string());
            file = GLib.File.new_for_path(CURRENT_PATH);
            if (file.query_exists() != true){file.make_directory();}
        }

        CURRENT_FILE_NAME = time.to_iso8601_string() + ".png";
    }

    private void get_pixbuf(){
        set_path_dir_and_file_path();
        string path = GLib.Path.build_filename(CURRENT_PATH, CURRENT_FILE_NAME);

        Gst.Element sink = player.get_by_name("gdkpixbufsink");
        Gdk.Pixbuf pixbuf; sink.get("last-pixbuf", out pixbuf);

        GLib.Idle.add (() => {save(pixbuf, path); return false;});

        /*
        //https://wiki.gnome.org/Projects/Vala/AsyncSamples
        Test.Async myasync = new Test.Async();
        GLib.MainLoop mainloop2 = new GLib.MainLoop();
        myasync.save.begin(pixbuf, path, (obj, res) => {
            //bool sentence = myasync.save.end(res);
            //GLib.stdout.printf("%s\n", sentence); GLib.stdout.flush();
            mainloop2.quit();});
        mainloop2.run();
        //GLib.stdout.printf("ON\n"); GLib.stdout.flush();
        */

        /*
        Gst.Element sink = player.get_by_name("gdkpixbufsink");
        Gdk.Pixbuf pixbuf; sink.get("last-pixbuf", out pixbuf);
        pixbuf.save(path, "png", null);*/
    }

    private bool save(Gdk.Pixbuf pixbuf, string path){
        GLib.File file = GLib.File.new_for_path(path);
        if (file.query_exists() != true){
            try {pixbuf.save(path, "png", null);}
            catch (Error err) {
                GLib.stdout.printf("Error: %s\n", err.message); GLib.stdout.flush();}}
        return false;
    }
}

/*
class Test.Async : GLib.Object {
    public async bool save(Gdk.Pixbuf pixbuf, string path) {
        GLib.File file = GLib.File.new_for_path(path);
        if (file.query_exists() != true){
            try {pixbuf.save(path, "png", null);}
            catch (Error err) {
                GLib.stdout.printf("Error: %s\n", err.message); GLib.stdout.flush();}}
        GLib.Idle.add(this.save.callback);
        yield;
        return true;
    }
}
*/


public static int main (string[] args) {
    Gst.init(ref args);
    new Camara();
    return 0;
}
