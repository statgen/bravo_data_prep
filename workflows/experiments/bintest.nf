process bintest {

  output:
  stdout into demo

  script:
  // executable files in bin/ should be in PATH for script
  """
  do_stuff.py
  """
}

demo.view()
