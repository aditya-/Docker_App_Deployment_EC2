<%@ taglib prefix="s" uri="/struts-tags" %>
<html>
    <head>
        <title>Company News</title>
				<link rel="stylesheet" href="styles/company.css" />
    </head>
    <body>
			<img src="images/logo.png">
    	<h1>Company News</h1>
        <div>
    	    <s:a action="Post">Post new item</s:a> (only if you're allowed to, please)
   	    </div>
        <s:iterator value="articles">
        	<h2>
        		<s:property value="title"/>
        	</h2>
        	<div>
        		<s:property value="body"/>
        	</div>
        	<div class="timestamp">
        		posted <s:date name="createDate" nice="true"/>
       		</div>
        </s:iterator>
    </body>
</html>
