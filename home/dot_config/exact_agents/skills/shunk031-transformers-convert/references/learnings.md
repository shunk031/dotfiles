# Project-Specific Learnings

This file accumulates knowledge from each conversion project to avoid repeating mistakes.

**Important**: When adding learnings from a new project, extract only the essential insights and generalizable lessons. Focus on:

- Key challenges unique to the project
- Solutions that can be applied to future conversions
- Patterns or anti-patterns discovered
- Configuration values that differ from expectations

Avoid verbose descriptions. Keep each entry concise and actionable.

---

## MVANet (Dichotomous Image Segmentation) - 2026-01-12

**Architecture**: Multi-view aggregation with SwinB backbone

**Key challenges & solutions**:

1. **MCRM pool_ratios mismatch**

   - Original implementation used `[2, 4, 8]` in actual model
   - Config had wrong default `[4, 8, 16]`
   - **Lesson**: Always verify default values match pretrained weights by tracing through actual model instantiation

2. **Multi-view architecture handling**

   - Model uses 4 local patches + 1 global view
   - Batch dimension needs careful handling: `batch_size * 5`
   - **Lesson**: Document multi-view assumptions clearly in config

3. **Preprocessing exact match**

   - torchvision.transforms vs numpy+torch gave identical results
   - Critical: use same resize method (BILINEAR) and exact same mean/std
   - **Lesson**: Preprocessing can be implemented differently as long as output is identical

4. **Double-resizing issue**

   - Tests showed 0.02% difference when using different preprocessed tensors
   - Using same tensor → bitwise identical outputs
   - **Lesson**: Always use SAME preprocessed tensor when comparing models for fair comparison

5. **Backbone output channels**

   - SwinB specific: [128, 128, 256, 512, 1024]
   - Made configurable for potential future backbone changes
   - **Lesson**: Make backbone-specific constants configurable even if unlikely to change

6. **Positional encoding buffer handling**

   - `dim_t` buffer needs explicit device movement
   - Not automatically moved by `.to(device)`
   - **Lesson**: Check all submodules for buffers that need manual device placement

7. **Auto\* class registration required for Hub**

   - Must call `register_for_auto_class()` on each class before pushing to Hub
   - Required for `from_pretrained()` to work correctly after uploading
   - **Lesson**: Always register custom models using `register_for_auto_class()`:
     ```python
     ModelConfig.register_for_auto_class()
     ModelForTask.register_for_auto_class("AutoModel")
     ImageProcessor.register_for_auto_class("AutoImageProcessor")
     ```
   - Best practice: Add registration in `__init__.py` so it happens on module import

8. **Image size order in post-processing**

   - `post_process_semantic_segmentation()` expects `target_sizes` as `(width, height)`
   - PIL `Image.size` returns `(width, height)` ✓
   - PIL `Image.width` and `Image.height` properties exist separately
   - **Lesson**: When using `target_sizes`, always use `(width, height)` order:

     ```python
     # Correct
     target_sizes = [(img.width, img.height) for img in images]
     # or
     w, h = img.size
     target_sizes = [(w, h)]

     # Wrong - causes width/height swap
     target_sizes = [(img.height, img.width)]
     ```

---

## [Project Name] ([Task Type]) - [Date]

**Architecture**: [Brief architecture description]

**Key challenges & solutions**:

1. **[Challenge name]**

   - [Description of challenge]
   - [How it was solved]
   - **Lesson**: [Generalizable insight for future conversions]

2. **[Challenge name]**
   - [Description]
   - [Solution]
   - **Lesson**: [Insight]

[Add more entries as you gain experience with different model types]
