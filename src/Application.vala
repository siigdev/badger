/*
 *  Copyright (C) 2019 Darshak Parikh
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  Authored by: Darshak Parikh <darshak@protonmail.com>
 *
 */

using Granite;
using Gtk;

public class Badger.Application : Granite.Application {

    public bool headless = false;

    private Badger.MainWindow window;

    public Application () {
        Object(
            application_id: "com.github.elfenware.badger",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        stdout.printf ("\n✔️ Activated");

        var settings = new GLib.Settings ("com.github.elfenware.badger.state");
        stdout.printf ("\n⚙️ State settings loaded");

        var first_run = settings.get_boolean ("first-run");

        if (first_run) {
            stdout.printf ("\n🎉️ First run");
            install_autostart ();
            settings.set_boolean ("first-run", false);
        }

        if (!headless && window != null) {
            stdout.printf ("\n▶️ Process already running. Presenting window...");
            window.present ();
        }

        window = new MainWindow (this);

        var reminders = set_up_reminders ();
        var main = new MainGrid (reminders);

        if (!headless) {
            window.add (main);
            window.show_all ();

            var provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/com/github/elfenware/badger/Application.css");
            Gtk.StyleContext.add_provider_for_screen (
                Gdk.Screen.get_default (),
                provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );
        } else {
            stdout.printf ("\n⚙️ Running in headless mode");
        }
    }

    public static int main (string[] args) {
        var app = new Badger.Application ();

        if (args.length > 1 && args[1] == "--headless") {
            app.headless = true;
        }

        return app.run (args);
    }

    private void install_autostart () {
        var desktop_file_name = application_id + ".desktop";
        var desktop_file_path = new DesktopAppInfo (desktop_file_name).filename;
        var desktop_file = File.new_for_path (desktop_file_path);
        var dest_path = Path.build_path (   Path.DIR_SEPARATOR_S,
                                            Environment.get_user_config_dir (),
                                            "autostart",
                                            desktop_file_name);
        var dest_file = File.new_for_path (dest_path);
        try {
            desktop_file.copy (dest_file, FileCopyFlags.OVERWRITE);
            stdout.printf ("\n📃️ Copied desktop file at: %s", dest_path);
        } catch (Error e) {
            warning ("Error making copy of desktop file for autostart: %s", e.message);
        }

        var keyfile = new KeyFile ();
        try {
            keyfile.load_from_file (dest_path, KeyFileFlags.NONE);
            keyfile.set_boolean ("Desktop Entry", "X-GNOME-Autostart-enabled", true);
            keyfile.set_string ("Desktop Entry", "Exec", application_id + " --headless");
            keyfile.save_to_file (dest_path);
        } catch (Error e) {
            warning ("Error enabling autostart: %s", e.message);
        }
    }

    private Reminder[] set_up_reminders () {
        Reminder[] reminders = new Reminder[5];
        reminders[0] = new Reminder (
            "eyes",
            _ ("Blink your eyes"),
            _ ("Look away from the screen and slowly blink your eyes for 10 seconds."),
            _ ("Blink eyes:"),
            1200,   // 20 minutes
            this
        );
        reminders[1] = new Reminder (
            "fingers",
            _ ("Stretch your fingers"),
            _ ("Spread out your palm wide, then close it into a fist. Repeat 5 times."),
            _ ("Stretch fingers:"),
            2100,   // 35 minutes
            this
        );
        reminders[2] = new Reminder (
            "arms",
            _ ("Stretch your arms"),
            _ ("Stretch your arms, and twist your wrists for 10 seconds."),
            _ ("Stretch arms:"),
            2520,   // 42 minutes
            this
        );
        reminders[3] = new Reminder (
            "legs",
            _ ("Stretch your legs"),
            _ ("Stand up, twist each ankle, and bend each knee."),
            _ ("Stretch legs:"),
            3300,   // 55 minutes
            this
        );
        reminders[4] = new Reminder (
            "neck",
            _ ("Turn your neck"),
            _ ("Turn your head in all directions. Repeat 3 times."),
            _ ("Turn neck:"),
            900,    // 15 minutes
            this
        );

        return reminders;
    }
}

