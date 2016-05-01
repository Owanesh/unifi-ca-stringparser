<?php
/*


*/
if ($_GET != null && isset($_GET)) {
    if (isset($_GET['auth_code']) && $_GET['auth_code'] != null && $_GET['auth_code'] != '') {
        if (strlen($_GET['auth_code']) == 24) {
            if (preg_match('/666sVtL7Rk/', $_GET['auth_code'])) {
                // I have true authorization code
          if (isset($_GET['mail_request']) && $_GET['mail_request'] != null && $_GET['mail_request'] != '') {
              $mail_request = $_GET['mail_request'];
              if (validEmail($mail_request)) {
                  if (isset($_GET['file_req']) && $_GET['file_req'] != null && $_GET['file_req'] != '') {
                      $file_req = ($_GET['file_req']);
                            /*  Saving on DB
                            +-+-+-+-+-+-+-+ */
                          $servername = 'localhost';
                      $username = 'root';
                      $password = 'root';
                      $dbname = 'elen';
                      $conn = new mysqli($servername, $username, $password, $dbname);
                      $sql = 'INSERT INTO elen_usrmail (mail) VALUES ("'.$mail_request.'")';
                      if ($conn->query($sql) === true) {
                          $file_url = 'http://elenlaser.com/img2/laserproduct/BladeRF_HighPeak-Power-Sealed.pdf';
                          header('Content-Type: application/octet-stream');
                          header('Content-Transfer-Encoding: Binary');
                          header('Content-disposition: attachment; filename="'.basename($file_url).'"');
                          readfile($file_url);
                          $conn->close();

                          header('Location: http:/google.com/'); /* Redirect browser */
                          exit;
                      } else {
                          echo 'Error: File not found';
                          $conn->close();

                      }
                  }
              }
          }
            }
        }
    }
} else {
    die();
}

/* PUBLIC FUNCION */
function validEmail($email)
{
    // First, we check that there's one @ symbol, and that the lengths are right
    if (!preg_match('/^[^@]{1,64}@[^@]{1,255}$/', $email)) {
        // Email invalid because wrong number of characters in one section, or wrong number of @ symbols.
        return false;
    }
    // Split it into sections to make life easier
    $email_array = explode('@', $email);
    $local_array = explode('.', $email_array[0]);
    for ($i = 0; $i < sizeof($local_array); ++$i) {
        if (!preg_match("/^(([A-Za-z0-9!#$%&'*+\/=?^_`{|}~-][A-Za-z0-9!#$%&'*+\/=?^_`{|}~\.-]{0,63})|(\"[^(\\|\")]{0,62}\"))$/", $local_array[$i])) {
            return false;
        }
    }
    if (!preg_match("/^\[?[0-9\.]+\]?$/", $email_array[1])) { // Check if domain is IP. If not, it should be valid domain name
        $domain_array = explode('.', $email_array[1]);
        if (sizeof($domain_array) < 2) {
            return false; // Not enough parts to domain
        }
        for ($i = 0; $i < sizeof($domain_array); ++$i) {
            if (!preg_match('/^(([A-Za-z0-9][A-Za-z0-9-]{0,61}[A-Za-z0-9])|([A-Za-z0-9]+))$/', $domain_array[$i])) {
                return false;
            }
        }
    }

    return true;
}

/**** PRESO DA WORDPRESS PER ESSERE SICURI CHE IL LINK NON SIA ALLA CAZZO *****/
function utf8_uri_encode($utf8_string, $length = 0)
{
    $unicode = '';
    $values = array();
    $num_octets = 1;
    $unicode_length = 0;

    $string_length = strlen($utf8_string);
    for ($i = 0; $i < $string_length; ++$i) {
        $value = ord($utf8_string[$i]);

        if ($value < 128) {
            if ($length && ($unicode_length >= $length)) {
                break;
            }
            $unicode .= chr($value);
            ++$unicode_length;
        } else {
            if (count($values) == 0) {
                $num_octets = ($value < 224) ? 2 : 3;
            }

            $values[] = $value;

            if ($length && ($unicode_length + ($num_octets * 3)) > $length) {
                break;
            }
            if (count($values) == $num_octets) {
                if ($num_octets == 3) {
                    $unicode .= '%'.dechex($values[0]).'%'.dechex($values[1]).'%'.dechex($values[2]);
                    $unicode_length += 9;
                } else {
                    $unicode .= '%'.dechex($values[0]).'%'.dechex($values[1]);
                    $unicode_length += 6;
                }

                $values = array();
                $num_octets = 1;
            }
        }
    }

    return $unicode;
}

 function seems_utf8($str)
 {
     $length = strlen($str);
     for ($i = 0; $i < $length; ++$i) {
         $c = ord($str[$i]);
         if ($c < 0x80) {
             $n = 0;
         } # 0bbbbbbb
        elseif (($c & 0xE0) == 0xC0) {
            $n = 1;
        } # 110bbbbb
        elseif (($c & 0xF0) == 0xE0) {
            $n = 2;
        } # 1110bbbb
        elseif (($c & 0xF8) == 0xF0) {
            $n = 3;
        } # 11110bbb
        elseif (($c & 0xFC) == 0xF8) {
            $n = 4;
        } # 111110bb
        elseif (($c & 0xFE) == 0xFC) {
            $n = 5;
        } # 1111110b
        else {
            return false;
        } # Does not match any model
        for ($j = 0; $j < $n; ++$j) { # n bytes matching 10bbbbbb follow ?
            if ((++$i == $length) || ((ord($str[$i]) & 0xC0) != 0x80)) {
                return false;
            }
        }
     }

     return true;
 }

 function sanitize($title)
 {
     $title = strip_tags($title);
    // Preserve escaped octets.
    $title = preg_replace('|%([a-fA-F0-9][a-fA-F0-9])|', '---$1---', $title);
    // Remove percent signs that are not part of an octet.
    $title = str_replace('%', '', $title);
    // Restore octets.
    $title = preg_replace('|---([a-fA-F0-9][a-fA-F0-9])---|', '%$1', $title);

     if (seems_utf8($title)) {
         if (function_exists('mb_strtolower')) {
             $title = mb_strtolower($title, 'UTF-8');
         }
         $title = utf8_uri_encode($title, 200);
     }

     $title = strtolower($title);
     $title = preg_replace('/&.+?;/', '', $title); // kill entities
    $title = str_replace('.', '-', $title);
     $title = preg_replace('/[^%a-z0-9 _-]/', '', $title);
     $title = preg_replace('/\s+/', '-', $title);
     $title = preg_replace('|-+|', '-', $title);
     $title = trim($title, '-');

     return $title;
 }
