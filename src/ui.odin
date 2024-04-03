package main

import mui "vendor:microui"
import gl "vendor:OpenGL"

test_window :: proc(ctx: ^mui.Context) {
    mui.begin(ctx)
    mui.begin_window(ctx, "test", {x = 0, y = 0, w = 100, h = 100})
    mui.end_window(ctx)
    mui.end(ctx)
}

render_ui :: proc(ctx: ^mui.Context) {
    cmd: ^mui.Command
    for(mui.next_command(ctx, &cmd)) {
        switch v in cmd.variant {
        case ^mui.Command_Text : render_text(v.str, v.pos, v.color)
        case ^mui.Command_Rect : render_rect(v.rect, v.color)
        case ^mui.Command_Clip : render_clip(v.rect)
        case ^mui.Command_Icon : render_icon(v.id, v.rect, v.color)
        case ^mui.Command_Jump : unreachable()
        }
    }
}

render_rect :: proc(rect: mui.Rect, color: mui.Color) {

}

render_text :: proc(str: string, pos: mui.Vec2, color: mui.Color) {

}

render_clip :: proc(rect: mui.Rect) {

}

render_icon :: proc(id: mui.Icon, rect: mui.Rect, color: mui.Color) {

}

unreachable :: proc() {

}