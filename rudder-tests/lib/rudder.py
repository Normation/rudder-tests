"""
  Define a Rudder report object string
  All parameters that are not given are replaced by a "*"
"""
class Report():
    def __init__(self, technique="*", status="*", ruleId="*", directiveId="*", versionId="*", component="*", key="*", timeStamp="*", nodeId="*", message="*"):
      self.technique = technique
      self.status = status
      self.ruleId = ruleId
      self.directiveId = directiveId
      self.versionId = versionId
      self.component = component
      self.key = key
      self.timeStamp = timeStamp
      self.nodeId = nodeId
      self.message = message

    def __repr__(self):
        return "@@%s@@%s@@%s@@%s@@%s@@%s@@%s@@%s##%s@#%s"%(self.technique, self.status, self.ruleId, self.directiveId, self.versionId, self.component, self.key, self.timeStamp, self.nodeId, self.message)

