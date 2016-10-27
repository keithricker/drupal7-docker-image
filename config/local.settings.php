<?php
/**
* Settings for local development
* For better portability we use environment variables.
*/

$src = $_ENV;

$databases = array (
'default' =>
array (
  'default' =>
  array (
    'database' => $src['MYSQL_ENV_MYSQL_DATABASE'],
    'username' => $src['MYSQL_PORT_3306_TCP_ADDR'],
    'password' => $src['MYSQL_ENV_MYSQL_PASSWORD'],
    'host' => $src['MYSQL_PORT_3306_TCP_ADDRESS'],
    'port' => $src['MYSQL_PORT_3306_TCP_PORT'],
    'driver' => 'mysql',
    'prefix' => '',
  ),
),
);

/*
 * Set a base_url with correct scheme, based on the current request. This is
 * used for internal links to stylesheets and javascript.
 */
$scheme = !empty($_SERVER['REQUEST_SCHEME']) ? $_SERVER['REQUEST_SCHEME'] : 'http';
$base_url = $scheme . '://' . $_SERVER['HTTP_HOST'];

/*
 * Set the private and temp directories
 */
$conf['file_private_path'] = !empty($src['DRUPAL_PRIVATE_DIR']) ? $src['DRUPAL_PRIVATE_DIR'] : 'sites/default/files/private';
$conf['file_temporary_path'] = !empty($src['DRUPAL_TMP_DIR']) ? $src['DRUPAL_TMP_DIR'] : 'tmp';
