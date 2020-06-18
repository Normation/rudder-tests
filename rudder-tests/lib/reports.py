from lxml import etree

class XMLReport:
  def __init__(self, path, workspace):
    self.path = path
    self.workspace = workspace

  """
    Each serverspec call (== each call to a test) will produce a report xml file.
    We need to merge them at runtime, and hierachize the report per scenario
  """
  def merge_reports(self, name, new_report=None):
    if new_report is None:
      new_report=self.workspace + "/serverspec-result.xml"
    try:
      single_tree = etree.parse(new_report)
      try:
        global_tree = etree.parse(self.path)
      except:
        global_tree = etree.ElementTree(etree.Element("testsuites", name=name))

      for element in single_tree.getroot().findall("testsuite"):
        global_tree.getroot().append(element)

      with open(self.path, 'wb+') as f:
        f.write(etree.tostring(global_tree))
    except:
      # dump partial report content in case of error
      try:
        with open(new_report, 'r') as fin:
          print(fin.read())
      except Exception as e:
          print(e)
