<template>
  <div class="min-h-screen p-10 bg-white">
    <h1 class="text-3xl font-bold mb-8 text-black">Debug Colors</h1>
    
    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
      
      <!-- Check standard Tailwind Primary -->
      <div class="p-6 border rounded">
        <h2 class="text-xl font-bold mb-4 text-black">1. Tailwind Class (bg-primary)</h2>
        <div class="w-full h-24 bg-primary rounded flex items-center justify-center text-white font-bold">
            bg-primary
        </div>
        <p class="mt-2 text-sm text-gray-600">Should be Blue #3571CB</p>
      </div>

      <!-- Check Raw CSS Variable -->
      <div class="p-6 border rounded">
        <h2 class="text-xl font-bold mb-4 text-black">2. Raw CSS Variable</h2>
        <div class="w-full h-24 rounded flex items-center justify-center text-white font-bold" style="background-color: var(--color-primary);">
            var(--color-primary)
        </div>
        <p class="mt-2 text-sm text-gray-600">Should be Blue #3571CB</p>
      </div>

       <!-- Check Text Color -->
      <div class="p-6 border rounded">
        <h2 class="text-xl font-bold mb-4 text-black">3. Text Primary</h2>
        <p class="text-primary text-4xl font-bold">
            This text should be Blue
        </p>
      </div>
      
    </div>

    <div class="mt-10 p-4 bg-gray-100 rounded">
        <h3 class="font-bold mb-2">Diagnostic Info:</h3>
        <p>If Box 1 is Mystery Blue and Box 2 is #3571CB: Tailwind config map is wrong.</p>
        <p>If Box 1 and Box 2 are both Mystery Blue: CSS Variable is being overridden.</p>
        <p>If Box 1 is Mystery Blue and Box 2 is Transparent/White: CSS file is NOT loaded.</p>
    </div>
  </div>
</template>
