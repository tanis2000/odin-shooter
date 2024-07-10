package math

Rect :: distinct [4]i32

rect_top :: proc(rect: Rect) -> i32 {
  return rect.y
}

rect_bottom :: proc(rect: Rect) -> i32 {
  return rect.y + rect.w
}

rect_left :: proc(rect: Rect) -> i32 {
  return rect.x
}

rect_right :: proc(rect: Rect) -> i32 {
  return rect.x + rect.z
}


RectF :: distinct [4]f32

rectf_top :: proc(rect: RectF) -> f32 {
  return rect.y
}

rectf_bottom :: proc(rect: RectF) -> f32 {
  return rect.y + rect.w
}

rectf_left :: proc(rect: RectF) -> f32 {
  return rect.x
}

rectf_right :: proc(rect: RectF) -> f32 {
  return rect.x + rect.z
}
