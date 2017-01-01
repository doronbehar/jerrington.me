--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend, (<>))
import           Hakyll
import           Text.Pandoc


--------------------------------------------------------------------------------

blogName = "Jacob Errington"

myDefaultContext
    = constField "blogName" blogName
    <> defaultContext

main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "font/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "files/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "files/pdfs/*" $ do
        route   idRoute
        compile copyFileCompiler

    create ["about.md", "projects.md"] $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" myDefaultContext
            >>= relativizeUrls

    create ["atom.xml"] $ do
      route idRoute
      compile $ do
        let feedCtx = postCtx <> bodyField "description"
        posts <- fmap (take 10) . recentFirst
          =<< loadAllSnapshots "posts/*" "content"
        renderAtom feedConfig feedCtx posts

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocMathCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "notes/*" $ do
        route $ setExtension "html"
        compile $ pandocMathCompiler
            >>= loadAndApplyTemplate "templates/post.html" postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let mostRecent = head posts

            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    myDefaultContext


            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    myDefaultContext

pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler
    = pandocCompilerWith readerOptions writerOptions where
        readerOptions = defaultHakyllReaderOptions
        writerOptions = defaultHakyllWriterOptions
            { writerHTMLMathMethod = MathJax ""
            }

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
  { feedTitle = "Jacob Thomas Errington's blog"
  , feedDescription = "Just another functional programming blog."
  , feedAuthorName = "Jacob Thomas Errington"
  , feedAuthorEmail = "blog@mail.jerrington.me"
  , feedRoot = "https://jerrington.me"
  }
