process multiline_params {

  output:
  stdout into demo

  script:
  """
  echo "Params"
  echo "${params.flags}"
  echo ""
  echo "${params.qc_metrics}"
  """
}

demo.view()
