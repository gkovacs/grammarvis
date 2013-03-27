<?php

header('Content-type: text/javascript');
$reqpath = $_SERVER["REQUEST_URI"];
$reqpath = str_replace('getParseHierarchyAndTranslations.php', 'getParseHierarchyAndTranslations', $reqpath);
echo file_get_contents('http://geza.csail.mit.edu:1357' . $reqpath);

?>
