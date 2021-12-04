return function(o)
  o.category{"Keypress", "Messages"}

  o.build{
    z = 0,
    t = "Fail Messages",
    d = "This toggle controls the notifications that are shown for various fail states.",
    f = "failMessage",
    v = true,
    o = 1
  }

  o.build{
    t = "Fail",
    f = "fail",
    i = 6
  }

  return o
end