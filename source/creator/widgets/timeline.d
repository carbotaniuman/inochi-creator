module creator.widgets.timeline;
import inochi2d;
import creator.widgets;
import bindbc.imgui;

enum MIN_TRACK_HEIGHT = 32;
enum MIN_HEADER_WIDTH = 128;
enum MAX_HEADER_WIDTH = MIN_HEADER_WIDTH*3;
enum DEF_HEADER_WIDTH = MAX_HEADER_WIDTH*0.75;
enum DRAG_SIZE = 4;
enum KF_SIZE = 6;

enum TIMELINE_MIN_ZOOM = 0.5;
enum TIMELINE_MAX_ZOOM = 10;

void incAnimationLaneHeader(ref AnimationLane lane, ref float width, ref float height) {

    igPushID(cast(void*)lane.paramRef);
    igPushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2(4, 0));
    igPushStyleColor(ImGuiCol.ChildBg, ImVec4(0, 0, 0, 0.15));
        if (igBeginChild("HEADER", ImVec2(width, height), true)) {

            incDummy(ImVec2(0, 8));
            igIndent();
                incText(lane.paramRef.targetParam.name);
                igSameLine(0, 0);
                incDummy(ImVec2(-24, 0));
                igSameLine(0, 0);
                incTextLabel(lane.paramRef.targetAxis == 0 ? "X" : "Y");
            igUnindent();

            incHeaderResizer(width, height, true);
        }
        igEndChild();
    igPopStyleColor();
    igPopStyleVar();
    igPopID();
}

/**
    Draws resizer for header
*/
void incHeaderResizer(ref float width, ref float height, bool side = false) {
    igPushID(side ? "LEFT_RESIZE" : "RIGHT_RESIZE");
        auto window = igGetCurrentWindow();
        auto drawList = igGetWindowDrawList();
        auto io = igGetIO();
        auto storage = igGetStateStorage();
        auto isResizingID = igGetID("IsResizing");
        auto resizeDirectionID = igGetID("ResizeDirection");

        auto isResizing = ImGuiStorage_GetBool(storage, isResizingID, false);
        auto resizeDir = ImGuiStorage_GetBool(storage, resizeDirectionID, false);
        ImVec2 start = ImVec2(
            window.OuterRectClipped.Max.x,
            window.OuterRectClipped.Max.y,
        );

        ImVec2 mousePos;
        igGetMousePos(&mousePos);

        ImVec2 size = ImVec2(
            window.WorkRect.Min.x-window.WorkRect.Max.x,
            window.WorkRect.Min.y-window.WorkRect.Max.y,
        );

        ImVec2 dragViewStart;
        ImVec2 dragViewEnd;
        bool isHovered;

        // Get data for the relevant side.
        if (side) {
            isHovered = mousePos.y > start.y+size.y-DRAG_SIZE && 
                        mousePos.y < start.y+size.y+DRAG_SIZE &&
                        mousePos.x > start.x && 
                        mousePos.x < start.x+size.x;
            dragViewStart = ImVec2(start.x, start.y+height);
            dragViewEnd = ImVec2(start.x+width, start.y+height);
            
        } else {
            isHovered = mousePos.y > start.y && 
                        mousePos.y < start.y+size.y &&
                        mousePos.x > start.x+size.x-DRAG_SIZE && 
                        mousePos.x < start.x+size.x+DRAG_SIZE;
            dragViewStart = ImVec2(start.x+width, start.y);
            dragViewEnd = ImVec2(start.x+width, start.y+height);
        }

        if (isResizing) {
            ImDrawList_AddLine(drawList, 
                dragViewStart,
                dragViewEnd,
                igGetColorU32(ImGuiCol.SeparatorActive, 0.5),
                DRAG_SIZE
            );

            // We're no longer resizing if the mouse button is up
            if (!io.MouseDown[ImGuiMouseButton.Left]) ImGuiStorage_SetBool(storage, isResizingID, false);

            if (resizeDir) {
                height = clamp(mousePos.y-start.y, MIN_TRACK_HEIGHT, float.max);
                igSetMouseCursor(ImGuiMouseCursor.ResizeNS);
            } else {
                width = clamp(mousePos.x-start.x, MIN_HEADER_WIDTH, MAX_HEADER_WIDTH);
                igSetMouseCursor(ImGuiMouseCursor.ResizeEW);
            }
        } else {
            if (isHovered) {
                ImDrawList_AddLine(drawList, 
                    dragViewStart,
                    dragViewEnd,
                    igGetColorU32(ImGuiCol.SeparatorHovered, 0.5),
                    DRAG_SIZE
                );

                // Set cursors
                if (side) igSetMouseCursor(ImGuiMouseCursor.ResizeNS);
                else igSetMouseCursor(ImGuiMouseCursor.ResizeEW);
                
                if (igIsMouseClicked(ImGuiMouseButton.Left)) {
                    ImGuiStorage_SetBool(storage, isResizingID, true);
                    ImGuiStorage_SetBool(storage, resizeDirectionID, side);
                }
            } else {
                ImDrawList_AddLine(drawList, 
                    dragViewStart,
                    dragViewEnd,
                    igGetColorU32(ImGuiCol.Separator, 0.5),
                    DRAG_SIZE
                );
            }
        }
    igPopID();
}

private {

}

enum FRAME_WIDTH = 16.0;

void incTimelineLane(ref AnimationLane lane, ref Animation anim, float height, float zoom, int idx) {
    auto window = igGetCurrentWindow();

    // Skip items if need be
    if (window.SkipItems) return;

    auto id = igGetID(&lane);

    float actualFrameSize = FRAME_WIDTH*zoom;
    float fullSize = actualFrameSize*(cast(float)anim.length-1);

    auto drawList = igGetWindowDrawList();
    auto io = igGetIO();
    auto storage = igGetStateStorage();

    

    ImVec2 start;
    igGetCursorScreenPos(&start);

    ImRect laneArea = ImRect(
        ImVec2(start.x, start.y),
        ImVec2(start.x+fullSize, start.y+height)
    );

    igPushStyleVar(ImGuiStyleVar.FrameBorderSize, 0);
        igRenderFrame(laneArea.Min, laneArea.Max, igGetColorU32(idx % 2 == 0 ? ImGuiCol.TableRowBg : ImGuiCol.TableRowBgAlt));
    igPopStyleVar();

    auto lineColor = igGetColorU32(ImGuiCol.Separator);

    igPushClipRect(laneArea.Min, laneArea.Max, true);
        // DRAW CONTENTS
        foreach(i; 0..anim.length) {
            float offsetX = start.x+(actualFrameSize*cast(float)i);

            ImDrawList_AddLine(drawList, ImVec2(offsetX, start.y), ImVec2(offsetX, start.y+height), lineColor);
        }

        float getKeyframeX(float value) {
            return start.x+(actualFrameSize*value);
        }

        float getKeyframeY(float value) {
            return (start.y+(height*(1-cast(float)value)));
        }

        if (lane.frames.length > 0) {
            size_t frameMax = lane.frames.length-1;
            size_t lastFrame = anim.length-1;

            ImDrawList_PathClear(drawList);
            foreach(i; 0..lane.frames.length) {
                Keyframe* prev = &lane.frames[max(cast(ptrdiff_t)i-1, 0)];
                Keyframe* curr = &lane.frames[i];
                Keyframe* next1 = &lane.frames[min(cast(ptrdiff_t)i+1, frameMax)];
                Keyframe* next2 = &lane.frames[min(cast(ptrdiff_t)i+2, frameMax)];

                if (prev == curr && prev.frame != 0) {
                    ImDrawList_PathLineTo(
                        drawList,
                        ImVec2(getKeyframeX(0), getKeyframeY(prev.value))
                    );
                }

                switch(lane.interpolation) {
                    case InterpolateMode.Stepped:
                        if (prev != curr) {
                            ImDrawList_PathLineTo(
                                drawList,
                                ImVec2(getKeyframeX(curr.frame), getKeyframeY(prev.value))
                            );
                        }
                        ImDrawList_PathLineTo(
                            drawList,
                            ImVec2(getKeyframeX(curr.frame), getKeyframeY(curr.value)),
                        );
                        break;

                    case InterpolateMode.Nearest:
                        break;
                    
                    case InterpolateMode.Linear:
                        if (prev != curr) {
                            ImDrawList_AddLine(
                                drawList,
                                ImVec2(getKeyframeX(prev.frame), getKeyframeY(prev.value)),
                                ImVec2(getKeyframeX(curr.frame), getKeyframeY(curr.value)),
                                igGetColorU32(ImGuiCol.PlotLines),
                                2
                            );
                        }
                        break;

                    case InterpolateMode.Cubic:
                        if (i == 0) ImDrawList_PathLineTo(drawList, ImVec2(getKeyframeX(prev.frame), getKeyframeY(prev.value)));
                        if (i % 4 == 1) {
                            ImDrawList_PathBezierCubicCurveTo(
                                drawList,
                                ImVec2(getKeyframeX(curr.frame), getKeyframeY(curr.value)),
                                ImVec2(getKeyframeX(next1.frame), getKeyframeY(next1.value)),
                                ImVec2(getKeyframeX(next2.frame), getKeyframeY(next2.value)),
                            );
                        }
                        break;

                    case InterpolateMode.Bezier:
                        break;

                    default: assert(0);
                }

                if (curr == next1 && next1.frame < lastFrame) {
                    ImDrawList_PathLineTo(
                        drawList,
                        ImVec2(getKeyframeX(lastFrame), getKeyframeY(next1.value)),
                    );
                }
            }

            ImDrawList_PathStroke(
                drawList,
                igGetColorU32(ImGuiCol.PlotLines),
                ImDrawFlags.RoundCornersAll,
                2
            );

            // Draw points after
            foreach(frame; lane.frames) {
                float kfX = getKeyframeX(frame.frame);
                float kfY = getKeyframeY(frame.value);
                ImDrawList_AddQuad(
                    drawList,
                    ImVec2(kfX, kfY-KF_SIZE),
                    ImVec2(kfX+KF_SIZE, kfY),
                    ImVec2(kfX, kfY+KF_SIZE),
                    ImVec2(kfX-KF_SIZE, kfY),
                    0xFF000000,
                    2
                );

                ImDrawList_AddQuadFilled(
                    drawList,
                    ImVec2(kfX, kfY-KF_SIZE),
                    ImVec2(kfX+KF_SIZE, kfY),
                    ImVec2(kfX, kfY+KF_SIZE),
                    ImVec2(kfX-KF_SIZE, kfY),
                    0xFF0000FF
                );
            }
        }
    igPopClipRect();

    igItemAdd(laneArea, id);
    igItemSize(ImVec2(fullSize, height));
}