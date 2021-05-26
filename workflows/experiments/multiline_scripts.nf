process multipass {

  output:
  stdout into demo

  script:
  // demonstrate multiline continuation works in scripts
  """
  echo -n\
    -e\
    "foo\nbar\nbaz"
  """
}

process multituple {
  input:
  val(hello) from Channel.from('Hola', 'Ciao', 'Hello', 'Bonjour', 'Halo')

  output:
  tuple stdout, 
    file("${hello}.txt") into temo

  script:
  """
  echo "$hello" > ${hello}.txt
  echo "$hello"
  """

}

demo.view()
temo.view()
