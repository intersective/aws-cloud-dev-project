## Constants

<dl>
<dt><a href="#db">db</a></dt>
<dd><p>A simple node.js API for use in an AWS cloud project</p>
<p>Code modified from @jacksonyuan-yt
https://github.com/jacksonyuan-yt/dynamodb-crud-api-gateway</p></dd>
</dl>

## Functions

<dl>
<dt><a href="#getPost">getPost(event)</a> ⇒</dt>
<dd><p>Get a post by postId.</p></dd>
<dt><a href="#createPost">createPost(event)</a> ⇒</dt>
<dd><p>Create a new post.</p></dd>
<dt><a href="#updatePost">updatePost(event)</a> ⇒</dt>
<dd><p>Update a post by postId.</p></dd>
<dt><a href="#deletePost">deletePost(event)</a> ⇒</dt>
<dd><p>Delete a post by postId.</p></dd>
<dt><a href="#getAllPosts">getAllPosts()</a> ⇒</dt>
<dd><p>Get all posts.</p></dd>
</dl>

<a name="db"></a>

## db
<p>A simple node.js API for use in an AWS cloud project</p>
<p>Code modified from @jacksonyuan-yt
https://github.com/jacksonyuan-yt/dynamodb-crud-api-gateway</p>

**Kind**: global constant  
<a name="getPost"></a>

## getPost(event) ⇒
<p>Get a post by postId.</p>

**Kind**: global function  
**Returns**: <p>The response object with the post data.</p>  

| Param | Description |
| --- | --- |
| event | <p>The event object containing the postId.</p> |

<a name="createPost"></a>

## createPost(event) ⇒
<p>Create a new post.</p>

**Kind**: global function  
**Returns**: <p>The response object with the creation result.</p>  

| Param | Description |
| --- | --- |
| event | <p>The event object containing the post data.</p> |

<a name="updatePost"></a>

## updatePost(event) ⇒
<p>Update a post by postId.</p>

**Kind**: global function  
**Returns**: <p>The response object with the update result.</p>  

| Param | Description |
| --- | --- |
| event | <p>The event object containing the postId and the new post data.</p> |

<a name="deletePost"></a>

## deletePost(event) ⇒
<p>Delete a post by postId.</p>

**Kind**: global function  
**Returns**: <p>The response object with the deletion result.</p>  

| Param | Description |
| --- | --- |
| event | <p>The event object containing the postId.</p> |

<a name="getAllPosts"></a>

## getAllPosts() ⇒
<p>Get all posts.</p>

**Kind**: global function  
**Returns**: <p>The response object with all the posts.</p>  
