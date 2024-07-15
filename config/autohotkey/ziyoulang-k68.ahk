# Requires AutoHotkey v2.0

; Left Alt = numeric layer
<!m::Send, 1

; numeric layer
; f1 - f12
; alt 4 = alt f4
; numeros nm,.jkluio = 0123456789
; espacio = 0
; h,9 = *       y,8 = /
; 0,p = -       ñ = +
; - = .
; backspace, home = del
; left = home
; right = end


; Right Alt = symbols layer

; numeric layer
; f1 - f12
; alt 4 = alt f4
; numeros nm,.jkluio = 0123456789
; espacio = 0
; h,9 = *       y,8 = /
; 0,p = -       ñ = +
; - = .
; backspace, home = del
; left = home
; right = end

; symbols layer
; backspace = del
; home = pause
; left = home
; right = end

; Right Control = media layer

;   ;; < >
;   let 102d
;   grt (around lsft 102d)
;   ;; shift symbols
;   sh2 (around lsft 2)
;   sh5 (around lsft 5)
;   sh7 (around lsft 7)
;   sh8 (around lsft 8)
;   sh9 (around lsft 9)
;   shm (around lsft ])
;   sho (around lsft [)
;   she (around lsft =)
;   shd (around lsft -)
;   ;; ctrl + alt
;   cal (around lalt lctl)
;   ;; hotkey
;   af4 (around lalt f4)
;   ;; right alt symbols
;   rmi (around ralt -)
;   roc (around ralt [)
;   rcc (around ralt ])
;   ras (around ralt 6)
;   rob (around ralt 7)
;   rcb (around ralt 0)
;   ron (around ralt 1)
;   rtw (around ralt 2)
;   rth (around ralt 3)
;   rfo (around ralt 4)
;   ;; media
;   vou KeyVolumeUp
;   vod KeyVolumeDown
;   som KeyMute
;   mpp KeyPlayPause
;   bnu KeyBrightnessUp
;   bnd KeyBrightnessDown
; )

; (defsrc
;   esc  1    2    3    4    5    6    7    8    9    0    -    =    bspc home
;   tab  q    w    e    r    t    y    u    i    o    p    [    ]    \    del
;   caps a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
;   lsft z    x    c    v    b    n    m    ,    .    /    rsft      up   pgdn
;   lctl lmet lalt           spc                 ralt      rctl left down rght
; )

; (deflayer base
;   esc  1    2    3    4    5    6    7    8    9    0    -    =    bspc home
;   tab  q    w    e    r    t    y    u    i    o    p    [    ]    \    del
;   caps a    s    d    f    g    h    j    k    l    ;    '    ret       pgup
;   lsft z    x    c    v    b    n    m    ,    .    /    rsft      up   pgdn
;   lctl lmet @num           spc                 @sym      @med left down rght
; )

; (deflayer numeric
;   _    _    _    _    @af4 _    _    _    @sh7 @shm /    _    _    del  del
;   _    f1   f2   f3   f4   _    @sh7 7    8    9    /    _    _    _    _
;   _    f5   f6   f7   f8   _    @shm 4    5    6    ]    _    _         _
;   _    f9   f10  f11  f12  _    0    1    2    3    .    _         _    _
;   _    lalt _              0                   .         _    home _    end
; )

; (deflayer symbols
;   @rmi @ron @rtw @rth @rfo @sh5 @ras _    _    _    @shd @sh8 @sh9 del  pause
;   _    =    @sh2 _    _    _    _    _    _    _    @sh7 @roc @rcc @rcb _
;   _    @rtw -    _    _    _    _    _    _    _    @shm @rob _         _
;   _    @let @grt _    _    @rtw _    _    _    @sho @she _         _    _
;   _    _    _              _                   _         _    home _    end
; )

; (deflayer media
;   _    _    _    _    _    _    _    _    _    _    _    _    _    _    _
;   _    _    _    _    _    _    _    _    _    _    _    _    _    _    _
;   _    _    _    _    _    _    _    _    _    _    _    _    @mpp      @bnu
;   _    _    _    _    _    _    _    _    _    _    _    @som      @vou @bnd
;   _    _    _              _                   _         _    home @vod end
; )