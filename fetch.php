<?php
$username = 'Hebbins';
$repository = 'LEAP-Fix';
$branch = 'main';
$file_path = 'LEAP-AIO.ps1';

// Construct the raw content URL
$raw_url = "https://raw.githubusercontent.com/{$username}/{$repository}/{$branch}/{$file_path}";

// Set headers for the request
$options = [
    'http' => [
        'method' => 'GET',
        'header' => [
            'User-Agent: PHP GitHub Raw Content Fetcher'
        ]
    ]
];

// Create stream context
$context = stream_context_create($options);

// Attempt to fetch the content
try {
    $content = file_get_contents($raw_url, false, $context);
    
    if ($content === false) {
        throw new Exception("Failed to fetch file content.");
    }
    
    // Output the raw content directly
    echo $content;
    
} catch (Exception $e) {
    // Display error message
    header("HTTP/1.1 500 Internal Server Error");
    echo "Error: " . $e->getMessage();
    exit;
}
?>