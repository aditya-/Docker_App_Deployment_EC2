<%@ taglib prefix="s" uri="/struts-tags" %>
<html>
<head>
	<link rel="stylesheet" href="styles/company.css" />
  <title>Post Company News Article</title>
</head>
<body>
	<img src="images/logo.png">
	<s:form action="Post"> 
	  <s:textfield label="Title" name="title"/>
	  <s:textarea label="Body" name="body" rows="30" cols="60" />
	  <s:submit/>
	</s:form>
</body>
</html>
