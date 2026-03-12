<?php
$username = 'Hebbins';
$repository = 'LEAP-Fix';
$branch = 'main';
$file_path = 'LEAP-AIO.ps1';

$raw_url = "https://raw.githubusercontent.com/{$username}/{$repository}/{$branch}/{$file_path}";

$options = [
    'http' => [
        'method' => 'GET',
        'header' => [
            'User-Agent: PHP GitHub Raw Content Fetcher'
        ]
    ]
];

$context = stream_context_create($options);

try {
    $content = file_get_contents($raw_url, false, $context);
    
    if ($content === false) {
        throw new Exception("Failed to fetch file content.");
    }
    echo $content;
    
} catch (Exception $e) {
    header("HTTP/1.1 500 Internal Server Error");
    echo "Error: " . $e->getMessage();
    exit;
}
?>