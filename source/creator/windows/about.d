module creator.windows.about;
import creator.windows;
import creator.core;
import creator;
import std.string;
import creator.utils.link;
import inochi2d;

class AboutWindow : Window {
protected:
    override
    void onBeginUpdate(int id) {
        flags |= ImGuiWindowFlags_NoResize;
        super.onBeginUpdate(0);
    }

    override
    void onUpdate() {

        igBeginChildStr("##LogoArea", ImVec2(512, 72), false, 0);
            igImage(
                cast(void*)incGetLogo(), 
                ImVec2(64, 64), 
                ImVec2(0, 0), 
                ImVec2(1, 1), 
                ImVec4(1, 1, 1, 1), 
                ImVec4(0, 0, 0, 0)
            );
            
            igSameLine(0, 8);
            igSeparatorEx(ImGuiSeparatorFlags_Vertical);
            igSameLine(0, 8);
            igBeginChildStr("##LogoTextArea", ImVec2(0, 0), false, 0);

                igPushFont(incBiggerFont());
                    igText("Inochi Creator");
                igPopFont();
                igText("%s", (INC_VERSION~"\0").ptr);
                igSeparator();
                igTextColored(ImVec4(0.5, 0.5, 0.5, 1), "I2D v. %s", (IN_VERSION~"\0").ptr);
            igEndChild();
        igEndChild();
        igBeginChildStr("##CreditsArea", ImVec2(512, 256), false, 0);

            igText("Created By");
            igSeparator();

            igText(import("CONTRIBUTORS.md"));

        igEndChild();

        if (igButton("Fork us on GitHub", ImVec2(0, 0))) {
            openLink("https://github.com/Inochi2D/inochi-creator");
        }

        igSameLine(0, 8);

        if (igButton("Donate", ImVec2(0, 0))) {
            openLink("https://www.patreon.com/clipsey");
        }

        igSameLine(0, 8);

        if (igButton("Follow us on Twitter", ImVec2(0, 0))) {
            openLink("https://twitter.com/Inochi2D");
        }


    }

public:
    this() {
        super("About");
    }
}